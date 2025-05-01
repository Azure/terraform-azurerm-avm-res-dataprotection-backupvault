# Disable the role_assignments rule validation as we're implementing a custom role assignment pattern
# where the scope is derived from other inputs rather than being directly part of the role_assignments variable.
# This is a deliberate design choice to maintain backward compatibility while providing proper role assignment functionality.
rule "role_assignments" {
  enabled = false
}