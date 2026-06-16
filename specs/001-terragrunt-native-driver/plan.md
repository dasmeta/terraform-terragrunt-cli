# Plan

## Summary

Refactor `terraform-terragrunt-cli` from a generated-Terraform-root model to a
Terragrunt-native unit model while preserving the shared YAML contract used by
the other drivers.

## Architecture

### Stays Shared

- YAML discovery and merge
- setup normalization
- linked setup detection
- linked setup name/path resolution inputs

### Moves Into Terragrunt Driver

- registry-native `terraform.source` rendering
- `inputs` rendering
- `dependency` block rendering
- `dependencies` block rendering
- any Terragrunt-native source/version transformations

### Removed From Terragrunt Driver

- dependency on shared full Terraform file rendering
- generated `main.tf`
- generated `versions.tf`
- generated `providers.tf`
- generated `outputs.tf`
- generated setup `README.md`

## Implementation Steps

1. Define the normalized Terragrunt unit model derived from current `local.units`.
2. Replace the current `module "terraform_setups"` usage with Terragrunt-native
   rendering modules/templates.
3. Teach the unit generator to render:
   - `terraform.source`
   - `inputs`
   - `dependency` blocks
   - `dependencies` blocks
4. Keep `root.hcl` generation and update it only as needed for shared
   Terragrunt settings.
5. Update examples:
   - `basic`
   - `with-shared-configs`
   - `linked-stacks`
6. Validate:
   - Terraform generation phase still converges cleanly
   - `terragrunt list`
   - `terragrunt dag graph`
   - linked example dependency/value wiring

## Risks

- Registry source translation may not be uniform across all possible YAML
  source formats.
- Linked output access through Terragrunt `dependency` may need output-name
  conventions aligned with YAML interpolation behavior.
- Some current examples may rely on generated Terraform-root assumptions and
  need to be rewritten.

## Validation Strategy

- prove no generated Terraform root setup directories remain per unit
- verify rendered `terragrunt.hcl` contains native source and dependency blocks
- verify linked example DAG remains correct
- verify linked inputs resolve against Terragrunt dependency outputs
