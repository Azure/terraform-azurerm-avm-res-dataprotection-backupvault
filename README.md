<!-- BEGIN_TF_DOCS -->
# Azure Verified Module for Azure Data Protection Backup Vault

This module provides a generic way to create and manage an Azure Data Protection Backup Vault resource.

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

## Features

- Deploys an Azure Data Protection Backup Vault with support for private endpoints, diagnostic settings, managed identities, resource locks, and role assignments.
- Supports AVM telemetry and tagging.
- Flexible configuration for private DNS zone group management.

## Example Usage

Here is an example of how you can use this module in your Terraform configuration:

```terraform
module "backup_vault" {
  source              = "Azure/avm-res-dataprotection-backupvault/azurerm"
  name                = "my-backupvault"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  enable_telemetry = true

  # Optional: configure private endpoints, diagnostic settings, managed identities, etc.
  # private_endpoints = { ... }
  # diagnostic_settings = { ... }
  # managed_identities = { ... }
  # tags = { environment = "production" }
}
```

## AVM Versioning Notice

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.7.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 5.0.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_data_protection_backup_instance_blob_storage.blob_backup_instance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_blob_storage) (resource)
- [azurerm_data_protection_backup_instance_disk.disk_backup_instance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_disk) (resource)
- [azurerm_data_protection_backup_instance_postgresql.postgresql_backup_instance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_postgresql) (resource)
- [azurerm_data_protection_backup_instance_postgresql_flexible_server.postgresql_flexible_backup_instance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_postgresql_flexible_server) (resource)
- [azurerm_data_protection_backup_policy_blob_storage.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_policy_blob_storage) (resource)
- [azurerm_data_protection_backup_policy_disk.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_policy_disk) (resource)
- [azurerm_data_protection_backup_policy_postgresql.postgresql_backup_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_policy_postgresql) (resource)
- [azurerm_data_protection_backup_policy_postgresql_flexible_server.postgresql_flexible_backup_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_policy_postgresql_flexible_server) (resource)
- [azurerm_data_protection_backup_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_vault) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_datastore_type"></a> [datastore\_type](#input\_datastore\_type)

Description: Specifies the type of the datastore. Changing this forces a new resource to be created.  
Valid options: ArchiveStore, OperationalStore, SnapshotStore, VaultStore.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of this resource. Must be between 5 and 50 characters long.

Type: `string`

### <a name="input_redundancy"></a> [redundancy](#input\_redundancy)

Description: Specifies the backup storage redundancy. Changing this forces a new resource to be created.  
Valid options: GeoRedundant, LocallyRedundant, ZoneRedundant.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_backup_policy_id"></a> [backup\_policy\_id](#input\_backup\_policy\_id)

Description: The ID of the Backup Policy that applies to the Backup Instance Blob Storage.

Type: `string`

Default: `null`

### <a name="input_backup_policy_name"></a> [backup\_policy\_name](#input\_backup\_policy\_name)

Description: The name which should be used for this Backup Policy Blob Storage.

Type: `string`

Default: `null`

### <a name="input_backup_repeating_time_intervals"></a> [backup\_repeating\_time\_intervals](#input\_backup\_repeating\_time\_intervals)

Description: Specifies a list of repeating time intervals in ISO 8601 format.

Type: `list(string)`

Default: `[]`

### <a name="input_blob_backup_instance_name"></a> [blob\_backup\_instance\_name](#input\_blob\_backup\_instance\_name)

Description: The name of the Backup Instance Blob Storage.

Type: `string`

Default: `null`

### <a name="input_cross_region_restore_enabled"></a> [cross\_region\_restore\_enabled](#input\_cross\_region\_restore\_enabled)

Description: Whether to enable cross-region restore for the Backup Vault. Can only be enabled with GeoRedundant redundancy.

Type: `bool`

Default: `false`

### <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key)

Description: A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.

Type:

```hcl
object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
```

Default: `null`

### <a name="input_default_retention_duration"></a> [default\_retention\_duration](#input\_default\_retention\_duration)

Description: The duration of the default retention rule in ISO 8601 format.

Type: `string`

Default: `null`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_disk_backup_instance_name"></a> [disk\_backup\_instance\_name](#input\_disk\_backup\_instance\_name)

Description: The name of the Backup Instance Disk.

Type: `string`

Default: `null`

### <a name="input_disk_id"></a> [disk\_id](#input\_disk\_id)

Description: The ID of the source Disk for Backup.

Type: `string`

Default: `null`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_identity_enabled"></a> [identity\_enabled](#input\_identity\_enabled)

Description: Whether to enable Managed Service Identity for the Backup Vault.

Type: `bool`

Default: `false`

### <a name="input_immutability"></a> [immutability](#input\_immutability)

Description: Immutability state: Disabled, Locked, or Unlocked.

Type: `string`

Default: `"Disabled"`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description: Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_operational_default_retention_duration"></a> [operational\_default\_retention\_duration](#input\_operational\_default\_retention\_duration)

Description: The duration of operational default retention rule in ISO 8601 format.

Type: `string`

Default: `null`

### <a name="input_pg_retention_rules"></a> [pg\_retention\_rules](#input\_pg\_retention\_rules)

Description: List of retention rules for PostgreSQL flexible server backup policy.

Type:

```hcl
list(object({
    name                   = string
    priority               = number
    duration               = string
    data_store_type        = optional(string, "VaultStore")
    absolute_criteria      = optional(string)
    days_of_week           = optional(list(string))
    months_of_year         = optional(list(string))
    scheduled_backup_times = optional(list(string))
    weeks_of_month         = optional(list(string))
  }))
```

Default: `[]`

### <a name="input_postgresql_backup_instance_name"></a> [postgresql\_backup\_instance\_name](#input\_postgresql\_backup\_instance\_name)

Description: The name of the Backup Instance PostgreSQL.

Type: `string`

Default: `null`

### <a name="input_postgresql_backup_policy_id"></a> [postgresql\_backup\_policy\_id](#input\_postgresql\_backup\_policy\_id)

Description: The ID of the Backup Policy PostgreSQL.

Type: `string`

Default: `null`

### <a name="input_postgresql_backup_policy_name"></a> [postgresql\_backup\_policy\_name](#input\_postgresql\_backup\_policy\_name)

Description: The name of the PostgreSQL Flexible Server Backup Policy.

Type: `string`

Default: `null`

### <a name="input_postgresql_database_id"></a> [postgresql\_database\_id](#input\_postgresql\_database\_id)

Description: The ID of the source PostgreSQL database.

Type: `string`

Default: `null`

### <a name="input_postgresql_flexible_backup_instance_name"></a> [postgresql\_flexible\_backup\_instance\_name](#input\_postgresql\_flexible\_backup\_instance\_name)

Description: The name of the PostgreSQL Flexible Server Backup Instance.

Type: `string`

Default: `null`

### <a name="input_postgresql_flexible_backup_policy_id"></a> [postgresql\_flexible\_backup\_policy\_id](#input\_postgresql\_flexible\_backup\_policy\_id)

Description: The ID of the PostgreSQL Flexible Server Backup Policy to use. If not provided, the module will create a policy.

Type: `string`

Default: `null`

### <a name="input_postgresql_flexible_server_id"></a> [postgresql\_flexible\_server\_id](#input\_postgresql\_flexible\_server\_id)

Description: The ID of the PostgreSQL Flexible Server to be backed up.

Type: `string`

Default: `null`

### <a name="input_postgresql_key_vault_secret_id"></a> [postgresql\_key\_vault\_secret\_id](#input\_postgresql\_key\_vault\_secret\_id)

Description: The ID of the key vault secret that stores the database credentials.

Type: `string`

Default: `null`

### <a name="input_retention_duration_in_days"></a> [retention\_duration\_in\_days](#input\_retention\_duration\_in\_days)

Description: The soft delete retention duration for this Backup Vault. Valid values are between 14 and 180. Defaults to 14.

Type: `number`

Default: `14`

### <a name="input_retention_rules"></a> [retention\_rules](#input\_retention\_rules)

Description: List of retention rules for the backup policy. Optional, can be left as an empty list.

Type:

```hcl
list(object({
    name     = string
    duration = optional(string, null) # Make duration optional to support both cases
    priority = number
    criteria = list(object({
      absolute_criteria      = string
      days_of_month          = optional(list(number), null)
      days_of_week           = optional(list(string), null)
      months_of_year         = optional(list(string), null)
      scheduled_backup_times = optional(list(string), null)
      weeks_of_month         = optional(list(string), null)
    }))
    life_cycle = optional(list(object({
      data_store_type = string
      duration        = string
    })), [])
  }))
```

Default: `[]`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A map of role assignments to create on resources. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `scope` - (Optional) The scope at which the role assignment applies to. Defaults to the backup vault resource ID.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    scope                                  = optional(string) # Added scope parameter
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_snapshot_resource_group_name"></a> [snapshot\_resource\_group\_name](#input\_snapshot\_resource\_group\_name)

Description: The name of the Resource Group where snapshots are stored.

Type: `string`

Default: `null`

### <a name="input_soft_delete"></a> [soft\_delete](#input\_soft\_delete)

Description: The state of soft delete for this Backup Vault. Valid options: AlwaysOn, Off, On. Defaults to On.  
Once set to AlwaysOn, the setting cannot be changed.

Type: `string`

Default: `"Off"`

### <a name="input_storage_account_container_names"></a> [storage\_account\_container\_names](#input\_storage\_account\_container\_names)

Description: Optional list of container names in the source Storage Account.

Type: `list(string)`

Default: `[]`

### <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id)

Description: The ID of the source Storage Account for the Backup Instance.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_time_zone"></a> [time\_zone](#input\_time\_zone)

Description: Specifies the Time Zone which should be used by the backup schedule.

Type: `string`

Default: `null`

### <a name="input_timeout_create"></a> [timeout\_create](#input\_timeout\_create)

Description: The timeout duration for creating the Backup Instance Blob Storage.

Type: `string`

Default: `"30m"`

### <a name="input_timeout_delete"></a> [timeout\_delete](#input\_timeout\_delete)

Description: The timeout duration for deleting the Backup Instance Blob Storage.

Type: `string`

Default: `"30m"`

### <a name="input_timeout_read"></a> [timeout\_read](#input\_timeout\_read)

Description: The timeout duration for reading the Backup Instance Blob Storage.

Type: `string`

Default: `"5m"`

### <a name="input_timeout_update"></a> [timeout\_update](#input\_timeout\_update)

Description: The timeout duration for updating the Backup Instance Blob Storage.

Type: `string`

Default: `"30m"`

### <a name="input_vault_default_retention_duration"></a> [vault\_default\_retention\_duration](#input\_vault\_default\_retention\_duration)

Description: The duration of vault default retention rule in ISO 8601 format.

Type: `string`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_backup_policy_blob_storage_id"></a> [backup\_policy\_blob\_storage\_id](#output\_backup\_policy\_blob\_storage\_id)

Description: The ID of the Blob Storage Backup Policy.

### <a name="output_backup_policy_id"></a> [backup\_policy\_id](#output\_backup\_policy\_id)

Description: The ID of the Backup Policy.

### <a name="output_backup_vault_id"></a> [backup\_vault\_id](#output\_backup\_vault\_id)

Description: The ID of the Backup Vault.

### <a name="output_blob_backup_instance_id"></a> [blob\_backup\_instance\_id](#output\_blob\_backup\_instance\_id)

Description: The ID of the Blob Backup Instance.

### <a name="output_identity_principal_id"></a> [identity\_principal\_id](#output\_identity\_principal\_id)

Description: The Principal ID for the Service Principal associated with the Identity of this Backup Vault.

### <a name="output_identity_tenant_id"></a> [identity\_tenant\_id](#output\_identity\_tenant\_id)

Description: The Tenant ID for the Service Principal associated with the Identity of this Backup Vault.

### <a name="output_lock_id"></a> [lock\_id](#output\_lock\_id)

Description: The resource ID of the management lock (if created)

### <a name="output_postgresql_flexible_backup_instance_id"></a> [postgresql\_flexible\_backup\_instance\_id](#output\_postgresql\_flexible\_backup\_instance\_id)

Description: The ID of the created PostgreSQL Flexible Server Backup Instance.

### <a name="output_postgresql_flexible_backup_policy_id"></a> [postgresql\_flexible\_backup\_policy\_id](#output\_postgresql\_flexible\_backup\_policy\_id)

Description: The ID of the created PostgreSQL Flexible Server Backup Policy.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ID of the Backup Vault

### <a name="output_vault_id"></a> [vault\_id](#output\_vault\_id)

Description: The resource ID of the Backup Vault

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->