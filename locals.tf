locals {
  root_shared_yaml = try(file("${var.yamldir}/_.yaml"), "")

  folders_shared_yaml = {
    for file in fileset(var.yamldir, "**/*/_.yaml") :
    replace(file, "/_.yaml$/", "") => try(file("${var.yamldir}/${file}"), "")
    if length(regexall("\\.terraform", file)) == 0
  }

  yaml_files_raw = {
    for file in fileset(var.yamldir, "**/*.yaml") :
    replace(file, "/.yaml$/", "") => try(
      yamldecode(
        join(
          "\n",
          concat(
            [local.root_shared_yaml],
            [for folder_name, shared_content in local.folders_shared_yaml : shared_content if strcontains(file, folder_name)],
            [file("${var.yamldir}/${file}")]
          )
        )
      ),
      {}
    )
    if length(regexall("\\.terraform", file)) == 0 && length(regexall("(^|/)_\\.yaml$", file)) == 0
  }

  yaml_files = {
    for key, item in local.yaml_files_raw :
    key => item
    if try(item.source, null) != null && try(item.version, null) != null
  }

  auto_detected_linked_workspaces = {
    for path, item in local.yaml_files :
    path => distinct([
      for match in flatten([
        for content in concat([try(item.variables, {})], try(item.providers, [])) :
        regexall("\\$${([^}]+)}", jsonencode(content))
      ]) :
      replace(match, "/(\\..+|\\[.+)/", "")
    ])
  }

  units = {
    for path, item in local.yaml_files :
    path => {
      name              = replace(path, "/[^a-zA-Z0-9_-]+/", "_")
      description       = "Generated unit for ${path}"
      module_source     = item.source
      module_version    = item.version
      module_vars       = try(item.variables, {})
      module_providers  = try(item.providers, [])
      linked_workspaces = distinct(concat(try(item.linked_workspaces, []), try(local.auto_detected_linked_workspaces[path], [])))
      terraform_backend = try(item.terraform_backend.name, null) == null && var.terraform_backend.name == null ? {
        name    = null
        configs = {}
        } : {
        name = coalesce(try(item.terraform_backend.name, null), var.terraform_backend.name)
        configs = merge(
          coalesce(var.terraform_backend.configs, {}),
          coalesce(try(item.terraform_backend.configs, null), {}),
          contains(keys(merge(coalesce(var.terraform_backend.configs, {}), coalesce(try(item.terraform_backend.configs, null), {}))), "path") ? {
            path = (
              endswith(tostring(merge(coalesce(var.terraform_backend.configs, {}), coalesce(try(item.terraform_backend.configs, null), {})).path), ".tfstate") ?
              "${dirname(tostring(merge(coalesce(var.terraform_backend.configs, {}), coalesce(try(item.terraform_backend.configs, null), {})).path))}/${path}/terraform.tfstate" :
              "${trimsuffix(tostring(merge(coalesce(var.terraform_backend.configs, {}), coalesce(try(item.terraform_backend.configs, null), {})).path), "/")}/${path}/terraform.tfstate"
            )
          } : {},
          contains(keys(merge(coalesce(var.terraform_backend.configs, {}), coalesce(try(item.terraform_backend.configs, null), {}))), "key") ? {
            key = "${trimsuffix(trimsuffix(tostring(merge(coalesce(var.terraform_backend.configs, {}), coalesce(try(item.terraform_backend.configs, null), {})).key), ".tfstate"), "/")}/${path}/terraform.tfstate"
          } : {},
          contains(keys(merge(coalesce(var.terraform_backend.configs, {}), coalesce(try(item.terraform_backend.configs, null), {}))), "workspace_key_prefix") ? {
            workspace_key_prefix = "${trimsuffix(tostring(merge(coalesce(var.terraform_backend.configs, {}), coalesce(try(item.terraform_backend.configs, null), {})).workspace_key_prefix), "/")}/${path}"
          } : {}
        )
      }
      output = {
        enabled   = try(item.output.enabled, true)
        sensitive = try(item.output.sensitive, null)
      }
      raw = item
    }
  }
}
