# terraform-terragrunt-cli

`terraform-terragrunt-cli` is a Terraform driver module that reads DasMeta-style YAML
definitions and generates Terragrunt-managed Terraform unit folders.

The repository currently focuses on the Terragrunt execution path. It keeps the
consumer interface intentionally close to `terraform-terramate-cli` so the
multi-driver boundary can be validated across more than one local runtime while
rendering Terragrunt-native units instead of Terraform root modules.

## What It Does

- reads multiple YAML files from a directory tree
- merges shared `_.yaml` content into child YAML files
- filters input down to module definitions that provide `source` and `version`
- generates one Terragrunt unit per resolved YAML file
- writes one shared `root.hcl` and one child `terragrunt.hcl` per unit
- writes generated `versions.tf` and `providers.tf` helper content through
  Terragrunt `generate` blocks when needed
- supports explicit `linked_workspaces` and auto-detected setup-output
  interpolation references
- renders native Terragrunt `dependency` and `dependencies` blocks for linked
  units
- generates `mock_outputs` for linked output references so `plan` and `validate`
  work before dependencies are applied; mocks are restricted to those commands so
  `apply` always uses real dependency state
- supports a root-level backend default with per-unit YAML override and isolated
  state identity per generated unit

## Minimal Example

```hcl
module "this" {
  source = "dasmeta/cli/terragrunt"

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
cd examples/linked-stacks/output && terragrunt run --all -- validate
cd examples/linked-stacks/output && terragrunt run --all -- plan
cd examples/linked-stacks/output && terragrunt run --all -- apply -auto-approve
```

`terragrunt run --all apply` applies units in dependency order: producers such as
`module-a` run before consumers such as `module-b`. Use `mock_outputs` only for
bootstrap `plan`/`validate`; apply resolves real outputs after dependencies are
applied in the same run.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_infra_yaml_loader"></a> [infra\_yaml\_loader](#module\_infra\_yaml\_loader) | dasmeta/generic/renderer//modules/infra-yaml-loader | 1.2.0 |
| <a name="module_root_generator"></a> [root\_generator](#module\_root\_generator) | ./modules/root-generator | n/a |
| <a name="module_unit_generators"></a> [unit\_generators](#module\_unit\_generators) | ./modules/unit-generator | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_mock_outputs_enabled"></a> [mock\_outputs\_enabled](#input\_mock\_outputs\_enabled) | Whether Terragrunt dependency mock\_outputs are enabled by default for consumer units. Individual unit YAML can override this with mock\_outputs.enabled. | `bool` | `true` | no |
| <a name="input_provider_configs"></a> [provider\_configs](#input\_provider\_configs) | Optional grouped provider-specific configuration rendered into generated Terragrunt helper files. | `any` | <pre>{<br/>  "aws": {<br/>    "custom_var_blocks": {},<br/>    "default_tags": {<br/>      "applied_from": "terragrunt",<br/>      "enabled": true,<br/>      "extra_tags": {},<br/>      "managed_by": "terraform"<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_targetdir"></a> [targetdir](#input\_targetdir) | The directory where generated Terragrunt units will be written. | `string` | `"./generated/units"` | no |
| <a name="input_terraform_backend"></a> [terraform\_backend](#input\_terraform\_backend) | Optional default Terraform backend configuration applied to generated units. | <pre>object({<br/>    name    = string            # Terraform backend type applied to generated Terragrunt units by default.<br/>    configs = optional(any, {}) # Backend configuration arguments applied to generated Terragrunt units by default.<br/>  })</pre> | <pre>{<br/>  "configs": null,<br/>  "name": null<br/>}</pre> | no |
| <a name="input_terraform_version"></a> [terraform\_version](#input\_terraform\_version) | The Terraform version constraint emitted into generated unit files. | `string` | `"~> 1.3"` | no |
| <a name="input_yamldir"></a> [yamldir](#input\_yamldir) | The directory where YAML module definitions are located. | `string` | `"."` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_generated_files"></a> [generated\_files](#output\_generated\_files) | Generated file paths written by the Terragrunt driver. |
| <a name="output_unit_paths"></a> [unit\_paths](#output\_unit\_paths) | Relative unit paths generated from the YAML directory tree. |
| <a name="output_units"></a> [units](#output\_units) | Normalized unit definitions derived from YAML input. |
| <a name="output_yaml_files"></a> [yaml\_files](#output\_yaml\_files) | Resolved YAML files after shared-config merge and filtering. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
