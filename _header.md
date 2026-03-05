# Azure Verified Module for Azure Data Protection Backup Vault

This module provides a generic way to create and manage an Azure Data Protection Backup Vault resource.

To use this module in your Terraform configuration, you'll need to provide values for the required variables.

## Features

- Deploys an Azure Data Protection Backup Vault with support for private endpoints, diagnostic settings, managed identities, resource locks, and role assignments.
- Supports AVM telemetry and tagging.
- Flexible configuration for private DNS zone group management.

## Deprecated: PostgreSQL Single Server Backup

Azure Database for PostgreSQL Single Server was [retired on 2025-03-28](https://techcommunity.microsoft.com/blog/adforpostgresql/retiring-azure-database-for-postgresql-single-server-in-2025/3783783). The `postgresql` backup type in this module targets the retired Single Server service and can no longer be used for new deployments.

- **For new PostgreSQL backups**, use the `postgresql_flexible` backup type which targets PostgreSQL Flexible Server. See the `postgres_flexible_backup` example.
- **For legacy Single Server backup support**, use [v1.2.0](https://github.com/Azure/terraform-azurerm-avm-res-dataprotection-backupvault/releases/tag/v1.2.0) of this module.

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
