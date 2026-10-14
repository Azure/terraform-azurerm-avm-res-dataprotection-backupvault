mock_provider "azapi" {}
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}
mock_provider "time" {}

run "kubernetes_backup_instance_omits_top_level_location" {
  command = apply

  override_resource {
    target = azapi_resource.backup_vault
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.DataProtection/backupVaults/testvault"
    }
  }

  variables {
    datastore_type      = "OperationalStore"
    enable_telemetry    = false
    location            = "eastus2"
    name                = "testvault"
    redundancy          = "LocallyRedundant"
    resource_group_name = "rg-test"
    backup_instances = {
      aks = {
        type                         = "kubernetes"
        name                         = "aks-backup-instance"
        backup_policy_key            = "aks"
        kubernetes_cluster_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-test"
        snapshot_resource_group_name = "rg-snapshots"
      }
    }
    backup_policies = {
      aks = {
        type                            = "kubernetes"
        name                            = "aks-policy"
        backup_repeating_time_intervals = ["R/2026-10-08T02:30:00+00:00/P1W"]
      }
    }
  }

  assert {
    condition     = azapi_resource.backup_instance_kubernetes_cluster["aks"].location != var.location
    error_message = "Kubernetes backup instances must not configure the module location as a top-level location because ARM omits it on read/import."
  }

  assert {
    condition     = azapi_resource.backup_instance_kubernetes_cluster["aks"].body.properties.dataSourceInfo.resourceLocation == var.location
    error_message = "The protected AKS cluster resourceLocation must still be sent in the backup instance body."
  }
}
