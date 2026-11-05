mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "time" {}

override_resource {
  target = azapi_resource.backup_vault
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DataProtection/backupVaults/testvault"
  }
}

override_resource {
  target = azapi_resource.backup_policy_blob_storage["blob"]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DataProtection/backupVaults/testvault/backupPolicies/blob-policy"
  }
}

variables {
  datastore_type      = "VaultStore"
  enable_telemetry    = false
  location            = "eastus2"
  name                = "testvault"
  redundancy          = "LocallyRedundant"
  resource_group_name = "rg-test"
  backup_policies = {
    blob = {
      type                            = "blob"
      name                            = "blob-policy"
      backup_repeating_time_intervals = ["R/2026-10-08T02:30:00+00:00/P1D"]
    }
  }
  backup_instances = {
    blob = {
      type                            = "blob"
      name                            = "blob-instance"
      backup_policy_key               = "blob"
      storage_account_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest"
      storage_account_container_names = ["container-one"]
    }
  }
}

run "blob_backup_instance_omits_datasource_set" {
  command = apply

  assert {
    condition     = !contains(keys(azapi_resource.backup_instance_blob_storage["blob"].body.properties), "dataSourceSetInfo")
    error_message = "Blob backup instances must omit dataSourceSetInfo from the request body."
  }
}
