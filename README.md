# terraform-terragrunt-cli

`terraform-terragrunt-cli` is a Terraform driver module that reads DasMeta-style YAML
definitions and generates Terragrunt-managed Terraform unit folders.

The repository currently focuses on the Terragrunt execution path. It keeps the
consumer interface intentionally close to `terraform-terramate-cli` so the multi-driver
boundary can be validated across more than one local runtime.

## What It Does

- reads multiple YAML files from a directory tree
- merges shared `_.yaml` content into child YAML files
- filters input down to module definitions that provide `source` and `version`
- generates one Terragrunt unit per resolved YAML file
- renders generic Terraform files through the shared `terraform-renderer-generic`
  module
- writes one shared `root.hcl` and one child `terragrunt.hcl` per unit
- supports explicit `linked_workspaces` and auto-detected setup-output
  interpolation references
- renders backend-aware Terraform remote-state wiring for linked units
- supports a root-level backend default with per-unit YAML override and isolated
  state identity per generated unit

## Minimal Example

```hcl
module "this" {
  source = "dasmeta/terraform-terragrunt-cli"

  yamldir   = "${path.module}/infra"
  targetdir = "${path.module}/generated/units"
}
```

Example YAML:

```yaml
source: dasmeta/empty/null
version: 1.2.2
```

## Inputs

- `yamldir`: directory containing YAML module definitions
- `targetdir`: output directory where generated Terragrunt units are written
- `terraform_version`: Terraform version constraint emitted into generated
  `versions.tf`
- `terraform_backend`: optional default backend configuration applied to
  generated units unless overridden in YAML

## Outputs

- `generated_files`: generated file paths
- `unit_paths`: generated unit-relative paths
- `units`: normalized unit definitions derived from YAML
- `yaml_files`: normalized YAML documents after shared-config merge

## Repository Layout

- root module: public driver interface
- `modules/root-generator`: shared Terragrunt root config generator
- `modules/unit-generator`: per-unit Terragrunt config generator
- `examples/basic`: basic usage and executable validation case
- `examples/with-shared-configs`: shared `_.yaml` executable validation case
- `examples/linked-stacks`: linked-unit and backend-aware executable validation
  case
- `docs/`: repository-local notes
- `specs/`: module-impacting change evidence

## Local Validation

Basic test:

```bash
terraform -chdir=examples/basic init -input=false
terraform -chdir=examples/basic apply -auto-approve
```

Shared-config test:

```bash
terraform -chdir=examples/with-shared-configs init -input=false
terraform -chdir=examples/with-shared-configs apply -auto-approve
```

Linked-units orchestration test:

```bash
terraform -chdir=examples/linked-stacks init -input=false
terraform -chdir=examples/linked-stacks apply -auto-approve
cd examples/linked-stacks/output && terragrunt list --format tree --dag --dependencies
cd examples/linked-stacks/output && terragrunt dag graph
```
