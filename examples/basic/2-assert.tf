locals {
  expected_unit_paths = tolist([
    "module-a",
    "module-b",
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

check "unit_paths_match_basic_fixture" {
  assert {
    condition     = tolist(module.this.unit_paths) == local.expected_unit_paths
    error_message = "Generated unit paths do not match the basic fixture."
  }
}

check "generated_files_match_basic_fixture" {
  assert {
    condition     = sort(module.this.generated_files) == local.expected_files
    error_message = "Generated file paths do not match the basic fixture."
  }
}
