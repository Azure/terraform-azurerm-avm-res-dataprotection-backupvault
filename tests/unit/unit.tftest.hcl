# tests/unit/unit.tftest.hcl

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
}
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

# Test 1: VaultStore creates a vault successfully
run "test_vaultstore" {
  command = apply

  variables {
    name                = "test-vault-store-default"
    location            = "eastus"
    resource_group_name = "rg-test"
    datastore_type      = "VaultStore"
    redundancy          = "LocallyRedundant"
  }

  assert {
    condition     = azapi_resource.backup_vault.name == "test-vault-store-default"
    error_message = "Backup vault name should match the provided name."
  }

  assert {
    condition = (
      length(azapi_resource.backup_vault.body.properties.storageSettings) == 1 &&
      azapi_resource.backup_vault.body.properties.storageSettings[0].datastoreType == "VaultStore"
    )
    error_message = "VaultStore configuration should result in a single storageSettings entry with datastoreType 'VaultStore'."
  }
}

# Test 2: ArchiveStore creates a vault successfully (the fix under test)
run "test_archivestore" {
  command = apply

  variables {
    name                = "test-vault-archive-store"
    location            = "eastus"
    resource_group_name = "rg-test"
    datastore_type      = "ArchiveStore"
    redundancy          = "LocallyRedundant"
  }

  assert {
    condition     = azapi_resource.backup_vault.name == "test-vault-archive-store"
    error_message = "Backup vault with ArchiveStore datastore type should be created."
  }

  assert {
    condition = (
      length(azapi_resource.backup_vault.body.properties.storageSettings) == 2 &&
      azapi_resource.backup_vault.body.properties.storageSettings[0].datastoreType == "ArchiveStore" &&
      azapi_resource.backup_vault.body.properties.storageSettings[1].datastoreType == "VaultStore"
    )
    error_message = "ArchiveStore configuration should result in two storageSettings entries: ArchiveStore and its companion VaultStore."
  }
}

# Test 3: SnapshotStore creates a vault successfully
run "test_snapshotstore" {
  command = apply

  variables {
    name                = "test-vault-snapshot-store"
    location            = "eastus"
    resource_group_name = "rg-test"
    datastore_type      = "SnapshotStore"
    redundancy          = "LocallyRedundant"
  }

  assert {
    condition     = azapi_resource.backup_vault.name == "test-vault-snapshot-store"
    error_message = "Backup vault with SnapshotStore datastore type should be created."
  }

  assert {
    condition = (
      length(azapi_resource.backup_vault.body.properties.storageSettings) == 1 &&
      azapi_resource.backup_vault.body.properties.storageSettings[0].datastoreType == "SnapshotStore"
    )
    error_message = "SnapshotStore configuration should result in a single storageSettings entry with datastoreType 'SnapshotStore'."
  }
}

# Test 4: OperationalStore creates a vault successfully
run "test_operationalstore" {
  command = apply

  variables {
    name                = "test-vault-operational"
    location            = "eastus"
    resource_group_name = "rg-test"
    datastore_type      = "OperationalStore"
    redundancy          = "LocallyRedundant"
  }

  assert {
    condition     = azapi_resource.backup_vault.name == "test-vault-operational"
    error_message = "Backup vault with OperationalStore should be created."
  }

  assert {
    condition = (
      length(azapi_resource.backup_vault.body.properties.storageSettings) == 1 &&
      azapi_resource.backup_vault.body.properties.storageSettings[0].datastoreType == "OperationalStore"
    )
    error_message = "OperationalStore configuration should result in a single storageSettings entry with datastoreType 'OperationalStore'."
  }
}

# Test 5: Invalid datastore_type is rejected
run "test_invalid_datastore_type" {
  command = plan

  variables {
    name                = "test-vault-invalid"
    location            = "eastus"
    resource_group_name = "rg-test"
    datastore_type      = "InvalidStore"
    redundancy          = "LocallyRedundant"
  }

  expect_failures = [
    var.datastore_type
  ]
}

# Test 6: Null values for alerts_for_all_job_failures and cross_subscription_restore_state are accepted (Issue #68)
run "test_null_validation_no_failure" {
  command = plan

  variables {
    name                           = "test-vault-null-validations"
    location                       = "eastus"
    resource_group_name            = "rg-test"
    datastore_type                 = "VaultStore"
    redundancy                     = "LocallyRedundant"
    alerts_for_all_job_failures    = null
    cross_subscription_restore_state = null
  }

  assert {
    condition     = azapi_resource.backup_vault.name == "test-vault-null-validations"
    error_message = "Vault should be created successfully with null validation values."
  }
}

# Test 7: Valid non-null values for alerts_for_all_job_failures
run "test_alerts_enabled_value" {
  command = plan

  variables {
    name                        = "test-vault-alerts-enabled"
    location                    = "eastus"
    resource_group_name         = "rg-test"
    datastore_type              = "VaultStore"
    redundancy                  = "LocallyRedundant"
    alerts_for_all_job_failures = "Enabled"
  }

  assert {
    condition     = azapi_resource.backup_vault.name == "test-vault-alerts-enabled"
    error_message = "Vault should be created with alerts_for_all_job_failures set to Enabled."
  }
}

# Test 8: Invalid alerts_for_all_job_failures value is rejected
run "test_invalid_alerts_value" {
  command = plan

  variables {
    name                        = "test-vault-invalid-alerts"
    location                    = "eastus"
    resource_group_name         = "rg-test"
    datastore_type              = "VaultStore"
    redundancy                  = "LocallyRedundant"
    alerts_for_all_job_failures = "InvalidValue"
  }

  expect_failures = [
    var.alerts_for_all_job_failures
  ]
}

# Test 9: Invalid resource guard ID is rejected (Issue #69)
run "test_invalid_resource_guard_id" {
  command = plan

  variables {
    name                       = "test-vault-invalid-guard"
    location                   = "eastus"
    resource_group_name        = "rg-test"
    datastore_type             = "VaultStore"
    redundancy                 = "LocallyRedundant"
    resource_guard_resource_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.resource_guard_resource_id
  ]
}
