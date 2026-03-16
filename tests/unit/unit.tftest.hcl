# tests/unit/unit.tftest.hcl

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
}
mock_provider "azurerm" {}
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
}

# Test 3: OperationalStore creates a vault successfully
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
}

# Test 4: Invalid datastore_type is rejected
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

# Test 5: Telemetry resource is created by default
run "test_telemetry_enabled" {
  command = apply

  variables {
    name                = "test-vault-telemetry"
    location            = "eastus"
    resource_group_name = "rg-test"
    datastore_type      = "VaultStore"
    redundancy          = "LocallyRedundant"
  }

  assert {
    condition     = can(modtm_telemetry.telemetry)
    error_message = "Telemetry resource should be created when enable_telemetry is true (default)."
  }
}
