terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "backup_mua_operator" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = module.backup_vault.resource_guard_id
  role_definition_name = "Backup MUA Operator"
}


# Naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"

  suffix = ["resourceguard"]
}

# Create a Resource Group
resource "azurerm_resource_group" "example" {
  location = "eastus2"
  name     = module.naming.resource_group.name_unique
  tags = {
    Environment = "Demo"
    Purpose     = "Resource Guard Example"
  }
}

# Create a Backup Vault with Resource Guard protection
module "backup_vault" {
  source = "../../"

  # Required parameters
  datastore_type      = "VaultStore"
  location            = azurerm_resource_group.example.location
  name                = module.naming.recovery_services_vault.name_unique
  redundancy          = "GeoRedundant"
  resource_group_name = azurerm_resource_group.example.name
  # Enable system-assigned managed identity
  managed_identities = {
    system_assigned = true
  }
  # Resource Guard configuration
  resource_guard_enabled = true
  resource_guard_name    = "${module.naming.recovery_services_vault.name_unique}-guard"
  # Tags
  tags = {
    Environment = "Demo"
    Service     = "Data Protection"
    CreatedBy   = "Terraform"
  }
  # Optional: exclude specific operations from protection
  vault_critical_operation_exclusion_list = [
    "Update" # Allow updates without Resource Guard protection
  ]
}


