locals {
  expected_unit_paths = tolist([
    "module-a",
    "nested/module-b",
  ])

  expected_files = sort(concat(
    ["./output/root.hcl"],
    flatten([
      for unit_path in local.expected_unit_paths : [
        "./output/${unit_path}/README.md",
        "./output/${unit_path}/main.tf",
        "./output/${unit_path}/outputs.tf",
        "./output/${unit_path}/terragrunt.hcl",
        "./output/${unit_path}/versions.tf",
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
