module "root_generator" {
  source = "./modules/root-generator"

  generated_dir       = var.targetdir
  generated_by_module = "dasmeta/terragrunt/cli"
}

module "terraform_setups" {
  source  = "dasmeta/generic/renderer"
  version = "1.0.3"

  for_each = local.units

  name       = each.value.name
  setup_path = each.key
  module_config = {
    source    = each.value.module_source
    version   = each.value.module_version
    variables = each.value.module_vars
    providers = each.value.module_providers
  }
  provider_custom_var_blocks = var.provider_custom_var_blocks
  linked_setups = {
    for linked_unit in each.value.linked_workspaces :
    linked_unit => {
      backend = local.units[linked_unit].terraform_backend.name
      config  = local.units[linked_unit].terraform_backend.configs
    }
    if try(local.units[linked_unit].terraform_backend.name, null) != null
  }
  output     = each.value.output
  target_dir = var.targetdir
  terraform = {
    version = var.terraform_version
    backend = each.value.terraform_backend
  }
  provider_default_tags = var.provider_default_tags
  generated_by_module   = "dasmeta/terragrunt/cli"
}

module "unit_generators" {
  source = "./modules/unit-generator"

  for_each = local.units

  generated_dir       = var.targetdir
  unit_path           = each.key
  unit_name           = each.value.name
  unit_description    = each.value.description
  linked_unit_paths   = each.value.linked_workspaces
  generated_by_module = "dasmeta/terragrunt/cli"
}
