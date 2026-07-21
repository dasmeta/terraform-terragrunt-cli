module "infra_yaml_loader" {
  #checkov:skip=CKV_TF_1: Registry module source uses version pin (CKV_TF_2)
  source  = "dasmeta/generic/renderer//modules/infra-yaml-loader"
  version = "1.2.1"

  yamldir = var.yamldir
}

module "root_generator" {
  source = "./modules/root-generator"

  generated_dir       = var.targetdir
  generated_by_module = "dasmeta/cli/terragrunt"
}

module "unit_generators" {
  source = "./modules/unit-generator"

  for_each = local.units

  generated_dir       = var.targetdir
  unit_path           = each.key
  unit_name           = each.value.name
  unit_description    = each.value.description
  module_source       = each.value.module_source
  module_version      = each.value.module_version
  module_vars         = each.value.module_vars
  module_providers    = each.value.module_providers
  linked_unit_paths   = each.value.linked_workspaces
  terraform_version   = var.terraform_version
  terraform_backend   = each.value.terraform_backend
  mock_outputs        = each.value.mock_outputs
  provider_configs    = var.provider_configs
  generated_by_module = "dasmeta/cli/terragrunt"
}
