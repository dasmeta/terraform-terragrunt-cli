locals {
  expected_unit_paths = tolist([
    "module-a",
    "nested/module-b",
  ])

  expected_files = sort(concat(
    ["./output/root.hcl"],
    flatten([
      for unit_path in local.expected_unit_paths : [
        "./output/${unit_path}/terragrunt.hcl",
      ]
    ])
  ))
}

check "unit_paths_match_shared_fixture" {
  assert {
    condition     = tolist(module.this.unit_paths) == local.expected_unit_paths
    error_message = "Generated unit paths do not match the shared-config fixture."
  }
}

check "generated_files_match_shared_fixture" {
  assert {
    condition     = sort(module.this.generated_files) == local.expected_files
    error_message = "Generated file paths do not match the shared-config fixture."
  }
}

check "shared_config_was_applied_to_nested_unit" {
  assert {
    condition     = module.this.yaml_files["nested/module-b"].source == "dasmeta/empty/null" && module.this.yaml_files["nested/module-b"].version == "1.2.2"
    error_message = "The nested unit did not resolve the shared YAML source/version configuration."
  }
}

data "local_file" "nested_module_b_terragrunt_hcl" {
  filename   = "${path.module}/output/nested/module-b/terragrunt.hcl"
  depends_on = [module.this]
}

check "shared_config_unit_uses_native_terragrunt_source" {
  assert {
    condition = alltrue([
      strcontains(data.local_file.nested_module_b_terragrunt_hcl.content, "source = \"tfr:///dasmeta/empty/null?version=1.2.2\""),
      strcontains(data.local_file.nested_module_b_terragrunt_hcl.content, "inputs ="),
    ])
    error_message = "The shared-config unit is not rendered as a Terragrunt-native unit."
  }
}
