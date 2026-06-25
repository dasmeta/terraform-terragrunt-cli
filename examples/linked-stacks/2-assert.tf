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

data "local_file" "root_hcl" {
  filename   = "${path.module}/output/root.hcl"
  depends_on = [module.this]
}

data "local_file" "module_b_terragrunt_hcl" {
  filename   = "${path.module}/output/module-b/terragrunt.hcl"
  depends_on = [module.this]
}

data "local_file" "module_a_terragrunt_hcl" {
  filename   = "${path.module}/output/module-a/terragrunt.hcl"
  depends_on = [module.this]
}

check "unit_paths_match_linked_fixture" {
  assert {
    condition     = tolist(module.this.unit_paths) == local.expected_unit_paths
    error_message = "Generated unit paths do not match the linked-stacks fixture."
  }
}

check "generated_files_match_linked_fixture" {
  assert {
    condition     = sort(module.this.generated_files) == local.expected_files
    error_message = "Generated file paths do not match the linked-stacks fixture."
  }
}

check "root_config_was_generated" {
  assert {
    condition     = strcontains(data.local_file.root_hcl.content, "generated_by")
    error_message = "The shared Terragrunt root.hcl was not generated as expected."
  }
}

check "linked_unit_declares_terragrunt_dependency" {
  assert {
    condition = alltrue([
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "find_in_parent_folders(\"root.hcl\")"),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "dependency \"module_a\""),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "dependencies"),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "../module-a"),
    ])
    error_message = "The linked Terragrunt unit does not declare dependency ordering for module-a."
  }
}

check "linked_unit_uses_dependency_outputs_for_interpolations" {
  assert {
    condition = alltrue([
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "source = \"tfr:///dasmeta/empty/null?version=1.2.2\""),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "inputs ="),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "dependency.module_a.outputs[\\\"first-string-variable\\\"]"),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "\"second-bool\":true"),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "mock_outputs"),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "first-string-variable"),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "mock_outputs_allowed_terraform_commands"),
    ])
    error_message = "The linked Terragrunt unit does not render native dependency output wiring for module-a interpolations."
  }
}

check "linked_units_render_isolated_remote_state" {
  assert {
    condition = alltrue([
      strcontains(data.local_file.module_a_terragrunt_hcl.content, "remote_state"),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "remote_state"),
      strcontains(data.local_file.module_a_terragrunt_hcl.content, "\"path\":\"./state/module-a/terraform.tfstate\""),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "\"path\":\"./state/module-b/terraform.tfstate\""),
      strcontains(data.local_file.module_a_terragrunt_hcl.content, "backend \"local\" {}"),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "backend \"local\" {}"),
    ])
    error_message = "Linked units do not render isolated Terragrunt remote_state paths from the global backend default."
  }
}
