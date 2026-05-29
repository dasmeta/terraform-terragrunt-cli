# unit-generator

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_file.generated_files](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_generated_by_module"></a> [generated\_by\_module](#input\_generated\_by\_module) | Module identifier written into generated files. | `string` | n/a | yes |
| <a name="input_generated_dir"></a> [generated\_dir](#input\_generated\_dir) | The directory where generated unit folders are written. | `string` | n/a | yes |
| <a name="input_linked_unit_paths"></a> [linked\_unit\_paths](#input\_linked\_unit\_paths) | Relative linked unit paths used for Terragrunt orchestration ordering. | `list(string)` | `[]` | no |
| <a name="input_unit_description"></a> [unit\_description](#input\_unit\_description) | Human-readable unit description. | `string` | n/a | yes |
| <a name="input_unit_name"></a> [unit\_name](#input\_unit\_name) | Normalized generated unit name. | `string` | n/a | yes |
| <a name="input_unit_path"></a> [unit\_path](#input\_unit\_path) | Relative generated unit path. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_generated_files"></a> [generated\_files](#output\_generated\_files) | Paths of files generated for this Terragrunt unit. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
