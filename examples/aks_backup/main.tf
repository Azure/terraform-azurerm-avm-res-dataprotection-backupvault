terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

provider "azapi" {}

data "azurerm_client_config" "current" {}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  suffix = ["aks"]
}

# ---------------------------------------------------------------------------
# Resource groups
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "example" {
  location = "eastus2"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_resource_group" "snap" {
  location = azurerm_resource_group.example.location
  name     = "${module.naming.resource_group.name_unique}-snap"
}

# ---------------------------------------------------------------------------
# AKS cluster
# ---------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "example" {
  location            = azurerm_resource_group.example.location
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "aks${substr(module.naming.kubernetes_cluster.name_unique, -6, -1)}"
  sku_tier            = "Standard"

  default_node_pool {
    name                        = "default"
    auto_scaling_enabled        = true
    max_count                   = 9
    min_count                   = 3
    orchestrator_version        = null
    os_disk_type                = "Managed"
    temporary_name_for_rotation = "tempnodepool"
    type                        = "VirtualMachineScaleSets"
    vm_size                     = "Standard_D4s_v3"
    zones                       = ["1", "2"]

    upgrade_settings {
      max_surge                     = "33%"
      drain_timeout_in_minutes      = 15
      node_soak_duration_in_minutes = 15
    }
  }
  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------------------------------------------------------
# Storage account — required by the AKS Data Protection extension
# ---------------------------------------------------------------------------
resource "azurerm_storage_account" "example" {
  account_replication_type        = "ZRS"
  account_tier                    = "Standard"
  location                        = azurerm_resource_group.example.location
  name                            = lower(replace("stgaks${substr(module.naming.resource_group.name_unique, -12, -1)}", "-", ""))
  resource_group_name             = azurerm_resource_group.example.name
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
}

resource "azurerm_storage_container" "example" {
  name                  = "backup"
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.example.id
}

# ---------------------------------------------------------------------------
# Kubernetes Data Protection extension
# ---------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster_extension" "backup_extension" {
  cluster_id     = azurerm_kubernetes_cluster.example.id
  extension_type = "Microsoft.DataProtection.Kubernetes"
  name           = "backup-extension"
  configuration_settings = {
    "configuration.backupStorageLocation.bucket"                = azurerm_storage_container.example.name
    "configuration.backupStorageLocation.config.resourceGroup"  = azurerm_resource_group.example.name
    "configuration.backupStorageLocation.config.storageAccount" = azurerm_storage_account.example.name
    "configuration.backupStorageLocation.config.subscriptionId" = data.azurerm_client_config.current.subscription_id
    "credentials.tenantId"                                      = data.azurerm_client_config.current.tenant_id
  }
  release_namespace = "dataprotection-microsoft"
  release_train     = "stable"
}

# Allow time for the extension pods to become ready before assigning roles
resource "time_sleep" "wait_for_extension" {
  create_duration = "5m"

  depends_on = [azurerm_kubernetes_cluster_extension.backup_extension]
}

# Grant the extension MSI write access to the backup storage account
resource "azurerm_role_assignment" "extension_storage_access" {
  principal_id         = azurerm_kubernetes_cluster_extension.backup_extension.aks_assigned_identity[0].principal_id
  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Account Contributor"

  depends_on = [time_sleep.wait_for_extension]
}

# ---------------------------------------------------------------------------
# Backup vault + policy (phase 1 — vault MSI must exist before RBAC below)
# The backup instance is intentionally omitted here so that all required RBAC
# and the trusted-access binding can be established before the instance is
# created.  See the azapi_resource.backup_instance block further below.
# ---------------------------------------------------------------------------
module "backup_vault" {
  source = "../../"

  datastore_type      = "VaultStore"
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.recovery_services_vault.name_unique}-vault"
  redundancy          = "LocallyRedundant"
  resource_group_name = azurerm_resource_group.example.name
  backup_policies = {
    aks = {
      type = "kubernetes"
      name = "${module.naming.kubernetes_cluster.name_unique}-policy"

      backup_repeating_time_intervals = ["R/2024-12-01T02:30:00+00:00/P1W"]
      time_zone                       = "UTC"

      default_retention_life_cycle = {
        data_store_type = "OperationalStore"
        duration        = "P14D"
      }

      retention_rules = [
        {
          name     = "Weekly"
          priority = 25
          duration = "P84D"
          criteria = [{ absolute_criteria = "FirstOfWeek" }]
        },
        {
          name     = "Monthly"
          priority = 20
          duration = "P365D"
          criteria = [{ absolute_criteria = "FirstOfMonth" }]
        }
      ]
    }
  }
  enable_telemetry = true
  managed_identities = {
    system_assigned = true
  }

  depends_on = [time_sleep.wait_for_extension]
}

# ---------------------------------------------------------------------------
# RBAC — all roles the vault MSI and AKS MSI need for backup operations
# These must be in place before the backup instance is created.
# ---------------------------------------------------------------------------

# Grants the backup vault's managed identity operator access to the AKS cluster
resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "backup_access" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  name                  = "backup-operator-binding"
  roles                 = ["Microsoft.DataProtection/backupVaults/backup-operator"]
  source_resource_id    = module.backup_vault.backup_vault_id
}

resource "azurerm_role_assignment" "required_roles" {
  for_each = {
    vault_cluster_reader = {
      role         = "Reader"
      scope        = azurerm_kubernetes_cluster.example.id
      principal_id = module.backup_vault.identity_principal_id
    }
    vault_snap_rg_reader = {
      role         = "Reader"
      scope        = azurerm_resource_group.snap.id
      principal_id = module.backup_vault.identity_principal_id
    }
    vault_snapshot_contributor = {
      role         = "Disk Snapshot Contributor"
      scope        = azurerm_resource_group.snap.id
      principal_id = module.backup_vault.identity_principal_id
    }
    vault_disk_operator = {
      role         = "Data Operator for Managed Disks"
      scope        = azurerm_resource_group.snap.id
      principal_id = module.backup_vault.identity_principal_id
    }
    vault_storage_contributor = {
      role         = "Storage Blob Data Contributor"
      scope        = azurerm_storage_account.example.id
      principal_id = module.backup_vault.identity_principal_id
    }
    cluster_snap_contributor = {
      role         = "Contributor"
      scope        = azurerm_resource_group.snap.id
      principal_id = azurerm_kubernetes_cluster.example.identity[0].principal_id
    }
  }

  principal_id         = each.value.principal_id
  scope                = each.value.scope
  role_definition_name = each.value.role
}

# Allow RBAC assignments to propagate across Azure AD before creating the
# backup instance — typically takes up to 2 minutes.
resource "time_sleep" "wait_for_rbac" {
  create_duration = "2m"

  depends_on = [
    azurerm_kubernetes_cluster_trusted_access_role_binding.backup_access,
    azurerm_role_assignment.extension_storage_access,
    azurerm_role_assignment.required_roles,
  ]
}

# ---------------------------------------------------------------------------
# Backup instance (phase 2 — created only after all RBAC is in place)
# ---------------------------------------------------------------------------
resource "azapi_resource" "backup_instance" {
  location  = azurerm_resource_group.example.location
  name      = "${module.naming.kubernetes_cluster.name_unique}-backup-instance"
  parent_id = module.backup_vault.backup_vault_id
  type      = "Microsoft.DataProtection/backupVaults/backupInstances@2025-07-01"
  body = {
    properties = {
      friendlyName = "${module.naming.kubernetes_cluster.name_unique}-backup-instance"
      objectType   = "BackupInstance"
      policyInfo = {
        policyId = module.backup_vault.kubernetes_backup_policy_ids["aks"]
      }
      dataSourceInfo = {
        datasourceType   = "Microsoft.ContainerService/managedClusters"
        objectType       = "DatasourceInfo"
        resourceId       = azurerm_kubernetes_cluster.example.id
        resourceLocation = azurerm_resource_group.example.location
      }
      dataSourceSetInfo = {
        objectType = "DatasourceSetInfo"
        resourceId = azurerm_kubernetes_cluster.example.id
      }
      datasourceParameters = {
        objectType                    = "KubernetesClusterBackupDatasourceParameters"
        clusterScopedResourcesEnabled = true
        excludedNamespaces            = ["kube-system", "kube-public"]
        excludedResourceTypes         = []
        includedNamespaces            = ["default", "app-namespace"]
        includedResourceTypes         = []
        labelSelectors                = []
        snapshotResourceGroupName     = azurerm_resource_group.snap.name
        volumeSnapshotEnabled         = true
      }
      validationType = "ShallowValidation"
    }
  }
  ignore_casing             = true
  ignore_missing_property   = true
  ignore_null_property      = true
  schema_validation_enabled = false

  depends_on = [time_sleep.wait_for_rbac]

  lifecycle {
    ignore_changes = [
      body.properties.dataSourceInfo.objectType,
      body.properties.dataSourceSetInfo.objectType,
    ]
  }
}
