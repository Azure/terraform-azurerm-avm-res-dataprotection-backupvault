terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Randomly select an Azure region for the resource group
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.7.0"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  suffix = ["blob"]
}

# Create a Resource Group in the randomly selected region
resource "azurerm_resource_group" "example" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Create a Storage Account for Blob Storage
resource "azurerm_storage_account" "example" {
  account_replication_type        = "ZRS"
  account_tier                    = "Standard"
  location                        = azurerm_resource_group.example.location
  name                            = module.naming.storage_account.name_unique
  resource_group_name             = azurerm_resource_group.example.name
  allow_nested_items_to_be_public = false

  # Add delay and cleanup for Azure Backup locks during destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Wait for Azure Backup to finish cleanup after backup instance destruction
      echo "Waiting for Azure Backup cleanup..."
      sleep 60

      # Try to remove any lingering backup locks
      STORAGE_ACCOUNT_NAME="${self.name}"
      RG_NAME="${self.resource_group_name}"

      echo "Checking for remaining Azure Backup locks on storage account $STORAGE_ACCOUNT_NAME..."
      az resource lock list --resource-group "$RG_NAME" --resource-name "$STORAGE_ACCOUNT_NAME" --resource-type "Microsoft.Storage/storageAccounts" --query "[?contains(name, 'AzureBackup') || contains(name, 'DoNotDelete')].{id:id, name:name}" -o tsv | while IFS=$'\t' read -r lock_id lock_name; do
        if [ -n "$lock_id" ]; then
          echo "Removing Azure Backup lock: $lock_name"
          az resource lock delete --ids "$lock_id" --yes || echo "Failed to remove lock $lock_name"
        fi
      done

      echo "Storage account cleanup completed"
    EOT

    on_failure = continue
  }
}

# Create a Storage Container
# Note: Due to Azure Data Protection automatically applying a scope lock on the storage account,
# this container cannot be deleted via Terraform once backup is configured.
# To clean up: manually remove the scope lock in Azure portal first, then run destroy.
resource "azurerm_storage_container" "example" {
  name                  = "example-container"
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.example.id

  depends_on = [terraform_data.backup_lock_cleanup]

  lifecycle {
    create_before_destroy = false
  }
}

# Module Call for Backup Vault
module "backup_vault" {
  source = "../../"

  datastore_type      = "VaultStore"
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.recovery_services_vault.name_unique}-vault"
  redundancy          = "LocallyRedundant"
  resource_group_name = azurerm_resource_group.example.name
  # Define backup instance
  backup_instances = {
    "blob-instance" = {
      type                            = "blob"
      name                            = "${module.naming.recovery_services_vault.name_unique}-blob-instance"
      backup_policy_key               = "blob-backup"
      storage_account_id              = azurerm_storage_account.example.id
      storage_account_container_names = [azurerm_storage_container.example.name]
    }
  }
  # Define backup policy
  backup_policies = {
    "blob-backup" = {
      type                                   = "blob"
      name                                   = "${module.naming.recovery_services_vault.name_unique}-backup-policy"
      backup_repeating_time_intervals        = ["R/2024-09-17T06:33:16+00:00/PT4H"]
      operational_default_retention_duration = "P30D"
      vault_default_retention_duration       = "P90D"
      time_zone                              = "Central Standard Time"
      retention_rules = [
        {
          name     = "Daily"
          duration = "P7D"
          priority = 25
          criteria = [{
            absolute_criteria = "FirstOfDay"
          }]
          life_cycle = [{
            data_store_type = "VaultStore"
            duration        = "P30D"
          }]
        },
        {
          name     = "Weekly"
          duration = "P7D"
          priority = 20
          criteria = [{
            absolute_criteria = "FirstOfWeek"
          }]
          life_cycle = [{
            data_store_type = "VaultStore"
            duration        = "P30D"
          }]
        }
      ]
    }
  }
  enable_telemetry = true
  lock             = null # Disable management lock to prevent destroy conflicts
  # Configure managed identity
  managed_identities = {
    system_assigned = true
  }
  soft_delete = "Off"
}

# Create role assignment outside the module to avoid circular dependencies
resource "azurerm_role_assignment" "storage_account_backup_contributor" {
  principal_id         = module.backup_vault.identity_principal_id
  scope                = azurerm_resource_group.example.id
  description          = "Backup Contributor for Blob Storage"
  role_definition_name = "Storage Account Backup Contributor"
}

# Resource to handle backup lock cleanup after backup vault destruction
resource "terraform_data" "backup_lock_cleanup" {
  triggers_replace = {
    backup_vault_id = module.backup_vault.backup_vault_id
    storage_account_id = azurerm_storage_account.example.id
  }

  # This provisioner runs when the backup vault changes (including destruction)
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Wait a bit for Azure to process backup destruction
      sleep 30

      # Remove any remaining Azure Backup locks from storage account
      STORAGE_ACCOUNT_ID="${self.triggers_replace.storage_account_id}"

      # List and remove backup-related locks
      az resource lock list --resource "$STORAGE_ACCOUNT_ID" --query "[?contains(name, 'AzureBackup') || contains(name, 'DoNotDelete')].{id:id, name:name}" -o tsv | while IFS=$'\t' read -r lock_id lock_name; do
        if [ -n "$lock_id" ]; then
          echo "Removing Azure Backup lock: $lock_name ($lock_id)"
          az resource lock delete --ids "$lock_id" || true
        fi
      done
    EOT

    on_failure = continue
  }
}


