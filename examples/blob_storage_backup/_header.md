# Blob Backup Storage Example

This example demonstrates how to deploy the `azurerm_data_protection_backup_vault` module with blob backup instance and policy for a comprehensive data protection solution.

This example specifically tests the fix for the Azure provider issue where `backup_repeating_time_intervals` with an empty list would cause validation errors. The backup policy uses an empty `backup_repeating_time_intervals = []` list, which would previously fail with:

```
Error: Not enough list items
Attribute backup_repeating_time_intervals requires 1 item minimum, but config has only 0 declared.
```

With our fix, the empty list is converted to `null` internally, preventing the validation error and allowing the deployment to succeed.
