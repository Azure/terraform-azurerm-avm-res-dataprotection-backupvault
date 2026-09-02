# The module's role assignment input intentionally extends the standard interface with name and scope.
rule "avm_interface_role_assignments" {
  enabled = false
}

# Existing backup instance resources do not yet propagate the module-level tags input.
rule "avm_azapi_resource_tags_required" {
  enabled = false
}
