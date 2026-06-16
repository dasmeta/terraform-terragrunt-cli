# Terragrunt-Native Driver

## Why

`terraform-terragrunt-cli` currently mirrors the Terraform Cloud and Terramate
drivers by generating a full Terraform root setup per unit and then placing a
`terragrunt.hcl` wrapper around it. This works, but it is not the most
idiomatic Terragrunt design.

Terragrunt can natively:

- point to Terraform Registry modules through `terraform.source`
- pass module inputs through `inputs`
- model ordering through `dependencies`
- consume linked setup outputs through `dependency`

The goal of this refactor is to keep the same YAML model used by the other
drivers while changing only the Terragrunt rendering path so the driver becomes
Terragrunt-native.

## Goals

- Keep the existing YAML contract portable across drivers.
- Avoid requiring YAML rewrites when switching between Terraform Cloud,
  Terramate, and Terragrunt.
- Stop generating full Terraform root setups for Terragrunt units.
- Generate Terragrunt-native configuration using registry module sources,
  inputs, and dependency blocks.
- Preserve linked setup detection and normalization as shared logic.

## Non-Goals

- Do not redesign the YAML format.
- Do not change Terraform Cloud driver behavior.
- Do not change Terramate driver behavior.
- Do not remove the shared linked-setup normalization logic from the generic
  renderer/shared layer.

## Required Behavior

### Shared YAML Contract

The same YAML setup definitions must remain valid for:

- `terraform-tfe-cloud`
- `terraform-terramate-cli`
- `terraform-terragrunt-cli`

That includes:

- module source
- module version
- module variables
- provider declarations
- linked setups
- shared config through `_.yaml`

### Terragrunt Rendering

Each generated unit must contain:

- a `terragrunt.hcl`
- shared inheritance from `root.hcl`
- native Terragrunt `terraform.source`
- native Terragrunt `inputs`

The driver should prefer registry-native module addressing when the YAML source
and version support it.

### Linked Setups

Linked setup handling for Terragrunt must use native Terragrunt constructs:

- `dependency` blocks for consuming linked outputs
- `dependencies` blocks for ordering

The driver must not rely on generated Terraform `data.terraform_remote_state`
for linked value consumption once the native refactor is complete.

### Portability

The Terragrunt-native rendering must be an execution concern only. It must not
introduce a new YAML-only field required exclusively by Terragrunt.

If Terragrunt-specific optional tuning is ever needed, it must be additive and
not required for core portability.

## Design Direction

### Shared Layer

The shared layer should continue to own:

- YAML discovery
- `_.yaml` merge behavior
- normalization of setup names and paths
- linked setup auto-detection
- merge of explicit and detected linked setups

### Terragrunt Driver Layer

The Terragrunt driver should own:

- conversion of normalized setup/module source into Terragrunt `terraform`
  source addressing
- generation of `root.hcl`
- generation of per-unit `terragrunt.hcl`
- generation of `dependency` and `dependencies` blocks
- translation of linked setup names into relative unit paths

### Shared Renderer Impact

`terraform-renderer-generic` should no longer be responsible for rendering
full Terraform setup files for Terragrunt units once the refactor is complete.

It may still remain relevant as a shared parsing/normalization dependency, but
Terragrunt should stop depending on it for generated `main.tf`,
`versions.tf`, `providers.tf`, `outputs.tf`, and `README.md`.

## Acceptance Criteria

- `terraform-terragrunt-cli` no longer generates full Terraform root setup
  directories for each unit.
- Generated units use Terragrunt-native `terraform.source` with module version
  support.
- Generated units use native `inputs`.
- Linked setup ordering is expressed through `dependencies`.
- Linked setup value consumption is expressed through `dependency` blocks.
- The same YAML examples continue to work for the Terragrunt driver without
  driver-specific YAML rewrites.
- Existing Terragrunt examples are updated to validate the native rendering
  path.
- Driver documentation explains the Terragrunt-native model and the difference
  from Terraform Cloud and Terramate.
