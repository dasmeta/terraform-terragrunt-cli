check "empty_yaml_files_are_ignored" {
  assert {
    condition     = length(module.this.unit_paths) == 0
    error_message = "Empty YAML files must not generate Terragrunt units."
  }
}
