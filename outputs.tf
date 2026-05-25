output "yaml_files" {
  value       = local.yaml_files
  description = "Resolved YAML files after shared-config merge and filtering."
}

output "units" {
  value       = local.units
  description = "Normalized unit definitions derived from YAML input."
}

output "unit_paths" {
  value       = sort(keys(local.units))
  description = "Relative unit paths generated from the YAML directory tree."
}

output "generated_files" {
  value = sort(flatten(concat(
    module.root_generator.generated_files,
    [for _, setup in module.terraform_setups : setup.generated_files],
    [for _, generator in module.unit_generators : generator.generated_files],
  )))
  description = "Generated file paths written by the Terragrunt driver."
}
