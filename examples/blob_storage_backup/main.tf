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
}

# Create a Storage Container
resource "azurerm_storage_container" "example" {
  name                  = "example-container"
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.example.id

  depends_on = [null_resource.cleanup_backup_locks]

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

# Add a dependency from storage container to backup vault to ensure proper destruction order
resource "null_resource" "backup_dependency" {
  depends_on = [module.backup_vault]
  
  triggers = {
    storage_account_id = azurerm_storage_account.example.id
    backup_vault_id    = module.backup_vault.resource.id
  }
}

# Cleanup resource to remove Azure Backup scope locks during destroy
resource "null_resource" "cleanup_backup_locks" {
  depends_on = [module.backup_vault]
  
  triggers = {
    storage_account_id = azurerm_storage_account.example.id
    resource_group_name = azurerm_resource_group.example.name
    container_name = azurerm_storage_container.example.name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Remove any backup scope locks from the storage account
      STORAGE_ACCOUNT_ID="${self.triggers.storage_account_id}"
      RG_NAME="${self.triggers.resource_group_name}"
      
      # Get storage account name from the ID
      STORAGE_ACCOUNT_NAME=$(echo $STORAGE_ACCOUNT_ID | sed 's|.*/||')
      
      # List and remove any backup-related locks
      az resource lock list --resource-group "$RG_NAME" --resource-name "$STORAGE_ACCOUNT_NAME" --resource-type "Microsoft.Storage/storageAccounts" --query "[?contains(name, 'AzureBackup') || contains(name, 'DoNotDelete')].id" -o tsv | while read lock_id; do
        if [ -n "$lock_id" ]; then
          echo "Removing lock: $lock_id"
          az resource lock delete --ids "$lock_id" || true
        fi
      done
    EOT
    
    on_failure = continue
  }
}


