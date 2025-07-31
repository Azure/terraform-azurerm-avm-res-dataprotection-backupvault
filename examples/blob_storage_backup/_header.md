# Blob Backup Storage Example

This example demonstrates how to deploy the `azurerm_data_protection_backup_vault` module with blob backup instances and policies for a comprehensive data protection solution.

This example specifically tests the fix for the Azure provider issue where `backup_repeating_time_intervals` with an empty list would cause validation errors. It includes:

1. A backup policy with specified time intervals (normal case)
2. A backup policy with empty time intervals (tests the fix for the provider quirk)

Both backup instances should deploy successfully, demonstrating that the module now gracefully handles empty `backup_repeating_time_intervals` lists by setting them to `null` internally.
