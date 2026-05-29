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
  source = "dasmeta/terragrunt/cli"

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
| <a name="module_root_generator"></a> [root\_generator](#module\_root\_generator) | ./modules/root-generator | n/a |
| <a name="module_terraform_setups"></a> [terraform\_setups](#module\_terraform\_setups) | dasmeta/generic/renderer | 1.0.0 |
| <a name="module_unit_generators"></a> [unit\_generators](#module\_unit\_generators) | ./modules/unit-generator | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_provider_custom_var_blocks"></a> [provider\_custom\_var\_blocks](#input\_provider\_custom\_var\_blocks) | Optional provider-specific custom blocks passed to the shared renderer. | `any` | `{}` | no |
| <a name="input_provider_default_tags"></a> [provider\_default\_tags](#input\_provider\_default\_tags) | Optional provider-specific default tag settings passed to the shared renderer. | `any` | <pre>{<br/>  "aws": {<br/>    "applied_from": "terragrunt",<br/>    "enabled": true,<br/>    "extra_tags": {},<br/>    "managed_by": "terraform"<br/>  }<br/>}</pre> | no |
| <a name="input_targetdir"></a> [targetdir](#input\_targetdir) | The directory where generated Terragrunt units will be written. | `string` | `"./generated/units"` | no |
| <a name="input_terraform_backend"></a> [terraform\_backend](#input\_terraform\_backend) | Optional default Terraform backend configuration applied to generated units. | <pre>object({<br/>    name    = string<br/>    configs = optional(any, {})<br/>  })</pre> | <pre>{<br/>  "configs": null,<br/>  "name": null<br/>}</pre> | no |
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
