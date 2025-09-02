# Copilot Instructions — AVM Terraform Module Development

> Use these rules whenever you write or edit Terraform for **Azure Verified Modules (AVM)**. Prefer the official AVM template, specs, and tooling. If anything here conflicts with the template/specs, follow the template/specs.

## Scope & Baseline
- Target **Terraform `>= 1.9, < 2.0`**.
- Use providers: **`azurerm ~> 4.x`**, **`azapi ~> 2.4`**, **`modtm ~> 0.3`**, **`random ~> 3.5`**.
- Start all new modules from **`Azure/terraform-azurerm-avm-template`** layout.
- Prefer `azurerm` for primary resources. Use `azapi` only where needed (child/extension resources or gaps). When using `azapi`, leverage **`Azure/avm-utl-interfaces`** outputs to build request bodies.

## Repository Layout (from template)
Keep these top-level files/folders up to date:
- `main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `terraform.tf`
- `main.telemetry.tf` (modtm telemetry, opt-out via `enable_telemetry`)
- Add `main.privateendpoint.tf` if the resource supports Private Endpoints
- `examples/` (at least one minimal, deployable example)
- `tests/` if applicable
- `.github/workflows/` (use central lint/e2e workflows as scaffolded)

## Required Inputs (resource modules)
Always expose these as **required**:
```hcl
variable "name"               { type = string }
variable "location"           { type = string }
variable "resource_group_name"{ type = string }
````

## Standard Interfaces (implement verbatim)

Use these exact shapes. Treat map keys as **arbitrary stable keys** for `for_each`.

### Tags

```hcl
variable "tags" { type = map(string), default = null }
```

### Lock

```hcl
variable "lock" {
  type = object({
    kind = string            # "CanNotDelete" | "ReadOnly"
    name = optional(string)  # null => generated
  })
  default = null
}
```

### Managed Identities

```hcl
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default = {}
}
```

### Diagnostic Settings (do **not** hardcode category allowlists)

```hcl
variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated") # or "AzureDiagnostics"
    workspace_resource_id                    = optional(string)
    storage_account_resource_id              = optional(string)
    event_hub_authorization_rule_resource_id = optional(string)
    event_hub_name                           = optional(string)
    marketplace_partner_resource_id          = optional(string)
  }))
  default = {}
}
```

### Role Assignments

```hcl
variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string)
    condition_version                      = optional(string) # "2.0" when used
    delegated_managed_identity_resource_id = optional(string)
    principal_type                         = optional(string)  # "User" | "Group" | "ServicePrincipal"
  }))
  default = {}
}
```

### Customer-Managed Key (CMK)

```hcl
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id  = string
    key_name               = string
    key_version            = optional(string)
    user_assigned_identity = optional(object({ resource_id = string }))
  })
  default = null
}
```

### Private Endpoints

```hcl
variable "private_endpoints" {
  type = map(object({
    name                                  = optional(string)
    subnet_resource_id                    = string
    private_dns_zone_group_name           = optional(string)
    private_dns_zone_resource_ids         = optional(set(string))
    application_security_group_resource_ids= optional(map(string))
    private_service_connection_name       = optional(string)
    network_interface_name                = optional(string)
    role_assignments                      = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      principal_type                         = optional(string)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string)
    }))
    tags = optional(map(string))
  }))
  default = {}
}

variable "private_endpoints_manage_dns_zone_group" {
  type    = bool
  default = true  # set to false to let policy or an external process manage DNS zone groups
}
```

## Telemetry (modtm)

* Expose:

```hcl
variable "enable_telemetry" { type = bool, default = true }
```

* Keep `main.telemetry.tf` from the template. If `enable_telemetry = false`, skip creating telemetry resources.

## Coding Rules (Terraform)

* **One primary resource per module**; compose additional child/extension resources inside that module only to add value.
* Prefer **`optional(...)`** typed inputs; avoid loose `any`.
* **Do not** set `nullable = true` by default.
* **Avoid** `sensitive = false`; never set defaults for sensitive inputs.
* Use `for_each` with stable keys (from maps) for extensibility (diag settings, PEs, role assignments).
* Do **not** hardcode diagnostic log/metric categories; accept them as inputs.
* No `null_resource` for core behavior; avoid shell‐outs for required logic.
* Keep naming flexible; don’t enforce opinionated naming inside the module—accept `name` and optional child names.

## Docs & Examples

* Auto-generate README with **`terraform-docs`** in PR checks.
* Provide at least:

  * A **minimal** `examples/default` that cleanly plans/applies/destroys.
  * Optional examples showing interfaces (PEs, CMK, diag) if the resource supports them.
* Expose helpful **outputs**: primary resource IDs and important child IDs/objects.

## Linting, Format, Tests (run locally before PR)

Use the template’s wrapper scripts (Docker-powered) from repo root:

```bash
# Linux/macOS/WSL
./avm pre-commit     # depsensure, fmt, fumpt, autofix, docs
./avm pr-check       # fmtcheck, tfvalidatecheck, tflint, unit-test (if present)

# Windows
avm.bat pre-commit
avm.bat pr-check
```

* Static analysis stack (centrally managed in CI): **avmfix**, **terraform-docs**, **TFLint (AVM ruleset)**, **grept**, **Conftest/OPA** (policy checks in e2e).
* If a rule truly needs an exception, add **`avm.tflint.override*.hcl`** in the correct scope (root/submodule/example) with a short rationale.
* For OPA exceptions in examples, add a `.rego` file under `examples/<name>/exceptions/`.

## PR & Release Flow (high level)

* Fork, branch, implement; run `./avm pre-commit && ./avm pr-check`.
* Open PR to the upstream module repo (`main`). Expect central **linting** + **e2e** workflows to run.
* Keep changes **non-breaking** (SemVer). If a breaking change is necessary, document clearly and bump **major**.

## When generating or editing code, **always**:

1. Conform to the interface shapes above.
2. Prefer `azurerm` for primary resource; use `avm-utl-interfaces` for AzAPI when needed.
3. Add/update examples and regenerate docs.
4. Make PR checks pass locally with the `avm` wrapper.

```

---

### Why these rules (notes & sources)

- **Template & versions** (Terraform `>=1.9,<2.0`, providers `azurerm~4`, `azapi~2.4`, `modtm~0.3`, `random~3.5`) and the **standard files** (`main.telemetry.tf`, `main.privateendpoint.tf`, `examples/`, wrapper scripts) come directly from the official **AVM Terraform template**. :contentReference[oaicite:0]{index=0}
- **Contribution flow & local commands** (`./avm pre-commit`, `./avm pr-check`) and what they run are documented in the AVM **Terraform Contribution Flow** and **Testing** pages; they also describe centralized lint/e2e workflows and policy checks with OPA/Conftest, plus TFLint override files. :contentReference[oaicite:1]{index=1}
- **Telemetry expectations** (modtm provider, opt-out via `enable_telemetry`) are in AVM’s Telemetry and Terraform Composition pages; `main.telemetry.tf` is distributed by the template. :contentReference[oaicite:2]{index=2}
- **Standard interface shapes** (diagnostic settings with arbitrary map keys & no category allowlists; managed identities; locks; private endpoints; role assignments; CMK) are reflected in the template’s input definitions and common AVM modules. :contentReference[oaicite:3]{index=3}
- **Use AzAPI only where needed** and the **`avm-utl-interfaces`** helper for AzAPI builds are demonstrated across AVM repos and the utility module docs. :contentReference[oaicite:4]{index=4}
- **Code-style rules** like avoiding `nullable = true`, not setting defaults for sensitive inputs, etc., are called out in the **Terraform Resource Module specifications**. :contentReference[oaicite:5]{index=5}

Want me to also generate a tiny `examples/default` skeleton (plus a `.tflint.hcl` with the AVM ruleset) that passes `./avm pr-check` out of the box?
::contentReference[oaicite:6]{index=6}
```
