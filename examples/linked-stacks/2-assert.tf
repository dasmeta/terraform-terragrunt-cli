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

data "local_file" "root_hcl" {
  filename   = "${path.module}/output/root.hcl"
  depends_on = [module.this]
}

data "local_file" "module_b_main_tf" {
  filename   = "${path.module}/output/module-b/main.tf"
  depends_on = [module.this]
}

data "local_file" "module_b_outputs_tf" {
  filename   = "${path.module}/output/module-b/outputs.tf"
  depends_on = [module.this]
}

data "local_file" "module_b_terragrunt_hcl" {
  filename   = "${path.module}/output/module-b/terragrunt.hcl"
  depends_on = [module.this]
}

data "local_file" "module_a_versions_tf" {
  filename   = "${path.module}/output/module-a/versions.tf"
  depends_on = [module.this]
}

data "local_file" "module_b_versions_tf" {
  filename   = "${path.module}/output/module-b/versions.tf"
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
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "dependencies"),
      strcontains(data.local_file.module_b_terragrunt_hcl.content, "../module-a"),
    ])
    error_message = "The linked Terragrunt unit does not declare dependency ordering for module-a."
  }
}

check "linked_unit_uses_remote_state_for_interpolations" {
  assert {
    condition = alltrue([
      strcontains(data.local_file.module_b_main_tf.content, "terraform_remote_state"),
      strcontains(data.local_file.module_b_main_tf.content, "module-a"),
      strcontains(data.local_file.module_b_main_tf.content, "outputs.results[\"first-string-variable\"]"),
      strcontains(data.local_file.module_b_outputs_tf.content, "value = module.this"),
    ])
    error_message = "The linked Terraform unit does not render backend-aware output wiring for module-a interpolations."
  }
}

check "linked_units_render_isolated_backend_state" {
  assert {
    condition = alltrue([
      strcontains(data.local_file.module_a_versions_tf.content, "backend \"local\""),
      strcontains(data.local_file.module_b_versions_tf.content, "backend \"local\""),
      strcontains(data.local_file.module_a_versions_tf.content, "path = \"./state/module-a/terraform.tfstate\""),
      strcontains(data.local_file.module_b_versions_tf.content, "path = \"./state/module-b/terraform.tfstate\""),
    ])
    error_message = "Linked units do not render isolated backend state paths from the global backend default."
  }
}
