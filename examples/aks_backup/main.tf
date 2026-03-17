terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

data "azurerm_client_config" "current" {}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  suffix = ["aks", "backup"]
}

locals {
  aks_cluster_name               = module.naming.kubernetes_cluster.name_unique
  backup_extension_name          = "azure-aks-backup"
  backup_extension_type          = "Microsoft.DataProtection.Kubernetes"
  backup_resource_group_location = "eastus"
  backup_resource_group_name     = "${module.naming.resource_group.name_unique}-data"
  backup_storage_name            = module.naming.storage_account.name_unique
  backuppolicy_name              = "aks-policy"
  backupvault_name               = module.naming.recovery_services_vault.name_unique
  datastore_type                 = "VaultStore"
  dns_prefix                     = "aksbackup"
  redundancy                     = "LocallyRedundant"
  resource_group_location        = "eastus"
  resource_group_name            = module.naming.resource_group.name_unique
}

# ---------------------------------------------------------------------------
# Resource groups
# ---------------------------------------------------------------------------
# Create a resource group for the backup vault and AKS cluster.
resource "azurerm_resource_group" "rg" {
  location = local.resource_group_location
  name     = local.resource_group_name
}

# Create a resource group for backup snapshots and storage.
resource "azurerm_resource_group" "backuprg" {
  location = local.backup_resource_group_location
  name     = local.backup_resource_group_name
}

# ---------------------------------------------------------------------------
# AKS cluster
# ---------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "akscluster" {
  location            = azurerm_resource_group.rg.location
  name                = local.aks_cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = local.dns_prefix

  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_A4_v2"
  }
  identity {
    type = "SystemAssigned"
  }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_resource_group.backuprg,
  ]
}

# ---------------------------------------------------------------------------
# Backup vault
# ---------------------------------------------------------------------------
module "backup_vault" {
  source = "../../"

  datastore_type      = local.datastore_type
  location            = azurerm_resource_group.rg.location
  name                = local.backupvault_name
  redundancy          = local.redundancy
  resource_group_name = azurerm_resource_group.rg.name
  backup_instances = {
    akstfbi = {
      type                         = "kubernetes"
      name                         = "example-internal-backup-instance"
      backup_policy_key            = "aks"
      snapshot_resource_group_name = azurerm_resource_group.backuprg.name

      kubernetes_cluster_id = azurerm_kubernetes_cluster.akscluster.id
      backup_datasource_parameters = {
        excluded_namespaces              = []
        excluded_resource_types          = []
        cluster_scoped_resources_enabled = true
        included_namespaces              = []
        included_resource_types          = []
        label_selectors                  = []
        volume_snapshot_enabled          = true
      }
    }
  }
  backup_policies = {
    aks = {
      type = "kubernetes"
      name = local.backuppolicy_name

      backup_repeating_time_intervals = ["R/2026-01-01T00:00:00+00:00/PT4H"]

      default_retention_life_cycle = {
        duration        = "P7D"
        data_store_type = "OperationalStore"
      }
    }
  }
  managed_identities = {
    system_assigned = true
  }
  role_assignments = {
    vault_msi_read_on_cluster = {
      role_definition_id_or_name = "Reader"
      scope                      = azurerm_kubernetes_cluster.akscluster.id
      principal_id               = "system-assigned"
      description                = "Allow backup vault to read AKS cluster properties for backup purposes."
      principal_type             = "ServicePrincipal"
    }
    vault_msi_read_on_snap_rg = {
      role_definition_id_or_name = "Reader"
      scope                      = azurerm_resource_group.backuprg.id
      principal_id               = "system-assigned"
      description                = "Allow backup vault to read snapshot resource group properties for backup purposes."
      principal_type             = "ServicePrincipal"
    }
  }
  soft_delete = "Off"

  depends_on = [azurerm_kubernetes_cluster.akscluster]
}

# ---------------------------------------------------------------------------
# Trusted access
# ---------------------------------------------------------------------------
# Create a trusted access role binding between AKS and backup vault.
resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "trustedaccess" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.akscluster.id
  name                  = "backuptrustedaccess"
  roles                 = ["Microsoft.DataProtection/backupVaults/backup-operator"]
  source_resource_id    = module.backup_vault.backup_vault_id

  depends_on = [
    module.backup_vault,
    azurerm_kubernetes_cluster.akscluster,
  ]
}

# ---------------------------------------------------------------------------
# Backup storage
# ---------------------------------------------------------------------------
# Create a storage account used by the AKS backup extension.
resource "azurerm_storage_account" "backupsa" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.backuprg.location
  name                     = local.backup_storage_name
  resource_group_name      = azurerm_resource_group.backuprg.name
}

# Create a blob container where backup data is stored.
resource "azurerm_storage_container" "backupcontainer" {
  name                  = "tfbackup"
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.backupsa.id

  depends_on = [azurerm_storage_account.backupsa]
}

# Create backup extension on the AKS cluster.
resource "azurerm_kubernetes_cluster_extension" "dataprotection" {
  cluster_id     = azurerm_kubernetes_cluster.akscluster.id
  extension_type = local.backup_extension_type
  name           = local.backup_extension_name
  configuration_settings = {
    "configuration.backupStorageLocation.bucket"                   = azurerm_storage_container.backupcontainer.name
    "configuration.backupStorageLocation.config.storageAccount"    = azurerm_storage_account.backupsa.name
    "configuration.backupStorageLocation.config.resourceGroup"     = azurerm_storage_account.backupsa.resource_group_name
    "configuration.backupStorageLocation.config.subscriptionId"    = data.azurerm_client_config.current.subscription_id
    "credentials.tenantId"                                         = data.azurerm_client_config.current.tenant_id
    "configuration.backupStorageLocation.config.useAAD"            = true
    "configuration.backupStorageLocation.config.storageAccountURI" = azurerm_storage_account.backupsa.primary_blob_endpoint
  }

  depends_on = [azurerm_storage_container.backupcontainer]
}

# ---------------------------------------------------------------------------
# Role assignments
# ---------------------------------------------------------------------------
# Assign role to extension identity on the storage account.
resource "azurerm_role_assignment" "extensionrole" {
  principal_id         = azurerm_kubernetes_cluster_extension.dataprotection.aks_assigned_identity[0].principal_id
  scope                = azurerm_storage_account.backupsa.id
  role_definition_name = "Storage Blob Data Contributor"

  depends_on = [azurerm_kubernetes_cluster_extension.dataprotection]
}

# Assign Contributor role to AKS identity over snapshot resource group.
resource "azurerm_role_assignment" "cluster_msi_contributor_on_snap_rg" {
  principal_id         = try(azurerm_kubernetes_cluster.akscluster.identity[0].principal_id, null)
  scope                = azurerm_resource_group.backuprg.id
  role_definition_name = "Contributor"

  depends_on = [
    azurerm_kubernetes_cluster.akscluster,
    azurerm_resource_group.backuprg,
  ]
}

# ---------------------------------------------------------------------------
# Backup instance
# ---------------------------------------------------------------------------
# resource "azurerm_data_protection_backup_instance_kubernetes_cluster" "akstfbi" {
#   name     = "example-external-backup-instance"
#   location = azurerm_resource_group.backuprg.location
#   vault_id = module.backup_vault.backup_vault_id

#   kubernetes_cluster_id        = azurerm_kubernetes_cluster.akscluster.id
#   snapshot_resource_group_name = azurerm_resource_group.backuprg.name
#   backup_policy_id             = module.backup_vault.kubernetes_backup_policy_ids["aks"]

#   backup_datasource_parameters {
#     excluded_namespaces              = []
#     excluded_resource_types          = []
#     cluster_scoped_resources_enabled = true
#     included_namespaces              = []
#     included_resource_types          = []
#     label_selectors                  = []
#     volume_snapshot_enabled          = true
#   }

#   depends_on = [
#     module.backup_vault,
#     azurerm_role_assignment.extensionrole,
#     azurerm_role_assignment.cluster_msi_contributor_on_snap_rg,
#   ]
# }
