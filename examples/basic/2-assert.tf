locals {
  expected_unit_paths = tolist([
    "module-a",
    "module-b",
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

data "local_file" "module_a_terragrunt_hcl" {
  filename   = "${path.module}/output/module-a/terragrunt.hcl"
  depends_on = [module.this]
}

check "units_use_terragrunt_native_source" {
  assert {
    condition = alltrue([
      strcontains(data.local_file.module_a_terragrunt_hcl.content, "source = \"tfr:///dasmeta/empty/null?version=1.2.2\""),
      strcontains(data.local_file.module_a_terragrunt_hcl.content, "inputs ="),
      strcontains(data.local_file.module_a_terragrunt_hcl.content, "generate \"versions\""),
    ])
    error_message = "The basic unit is not rendered as a Terragrunt-native unit."
  }
}
