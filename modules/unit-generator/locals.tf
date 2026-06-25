locals {
  note                               = "This file and its content are generated based on config, pleas check README.md for more details"
  unit_path_parts                    = split("/", var.unit_path)
  module_source_is_registry          = length(regexall("^[^/]+/[^/]+/[^/]+(//.*)?$", var.module_source)) > 0
  module_source_is_prefixed_registry = startswith(var.module_source, "tfr://")
  module_source_has_query            = length(regexall("\\?", var.module_source)) > 0
  module_source_is_git_like          = startswith(var.module_source, "git::") || length(regexall("^(ssh|https?)://", var.module_source)) > 0 || length(regexall("^[^/]+@[^:]+:.+$", var.module_source)) > 0
  module_source_has_ref              = length(regexall("([?&])ref=", var.module_source)) > 0

  terraform_source = (
    local.module_source_is_prefixed_registry ? (
      local.module_source_has_query ? var.module_source : "${var.module_source}?version=${var.module_version}"
      ) : (
      local.module_source_is_registry ? "tfr:///${var.module_source}?version=${var.module_version}" : (
        local.module_source_is_git_like ? (
          local.module_source_has_ref ? var.module_source : "${var.module_source}${local.module_source_has_query ? "&" : "?"}ref=${var.module_version}"
        ) : var.module_source
      )
    )
  )

  linked_unit_configs = [
    for linked_unit_path in var.linked_unit_paths : {
      path = linked_unit_path
      name = replace(linked_unit_path, "/[^a-zA-Z0-9_]+/", "_")
      config_path = join(
        "/",
        concat(
          [
            for _ in range(
              length(local.unit_path_parts) - length([
                for idx in range(min(length(local.unit_path_parts), length(split("/", linked_unit_path)))) : idx
                if slice(local.unit_path_parts, 0, idx + 1) == slice(split("/", linked_unit_path), 0, idx + 1)
              ])
            ) : ".."
          ],
          slice(
            split("/", linked_unit_path),
            length([
              for idx in range(min(length(local.unit_path_parts), length(split("/", linked_unit_path)))) : idx
              if slice(local.unit_path_parts, 0, idx + 1) == slice(split("/", linked_unit_path), 0, idx + 1)
            ]),
            length(split("/", linked_unit_path))
          )
        )
      )
      mock_outputs = try(local.dependency_mock_outputs[linked_unit_path], {})
    }
  ]

  linked_reference_expressions = distinct(flatten([
    for var_value in values(var.module_vars) :
    [for match in regexall("\\$\\{([^}]+)\\}", jsonencode(var_value)) : replace(match[0], "\\\"", "\"")]
  ]))

  dependency_mock_output_keys = {
    for linked_path in var.linked_unit_paths :
    linked_path => distinct(compact(concat(
      [
        for expression in local.linked_reference_expressions :
        trimsuffix(trimprefix(expression, "${linked_path}[\""), "\"]")
        if startswith(expression, "${linked_path}[\"")
      ],
      [
        for expression in local.linked_reference_expressions :
        trimprefix(expression, "${linked_path}.")
        if startswith(expression, "${linked_path}.") && !can(regex("^\\[", trimprefix(expression, "${linked_path}.")))
      ]
    )))
  }

  dependency_mock_outputs = var.mock_outputs.enabled ? {
    for linked_path, output_keys in local.dependency_mock_output_keys :
    linked_path => merge(
      { for output_key in output_keys : output_key => "mock-${output_key}" },
      try(var.mock_outputs.values[linked_path], {})
    )
  } : {}

  linked_setup_mapping = {
    for item in local.linked_unit_configs :
    item.path => "dependency.${item.name}.outputs"
  }

  provider_custom_var_blocks = {
    for provider_name, provider_config in var.provider_configs :
    provider_name => try(provider_config.custom_var_blocks, {})
    if try(provider_config.custom_var_blocks, null) != null
  }
  aws_default_tags_config = try(var.provider_configs.aws.default_tags, null)
  aws_generated_default_tags = local.aws_default_tags_config != null && try(local.aws_default_tags_config.enabled, false) ? {
    default_tags = {
      tags = merge(
        {
          ManagedBy              = try(local.aws_default_tags_config.managed_by, "terraform")
          TerraformModuleSource  = var.module_source
          TerraformModuleVersion = var.module_version
        },
        try(local.aws_default_tags_config.applied_from, null) != null ? {
          AppliedFrom = local.aws_default_tags_config.applied_from
        } : {},
        try(local.aws_default_tags_config.extra_tags, {})
      )
    }
  } : {}

  effective_provider_custom_var_blocks = merge(
    local.provider_custom_var_blocks,
    local.aws_generated_default_tags != {} ? {
      aws = provider::deepmerge::mergo(try(local.provider_custom_var_blocks.aws, {}), local.aws_generated_default_tags)
    } : {}
  )

  rendered_provider_custom_var_blocks = {
    for provider_name, provider_blocks in local.effective_provider_custom_var_blocks :
    provider_name => {
      for key, value in provider_blocks :
      key => (
        length(local.linked_setup_mapping) > 0 ?
        jsondecode(format(
          replace(replace(jsonencode(value), "%", "%%"), "/(${join("|", keys(local.linked_setup_mapping))})/", "%s"),
          [for linked_key in flatten(regexall("(${join("|", keys(local.linked_setup_mapping))})", replace(jsonencode(value), "%", "%%"))) : try(local.linked_setup_mapping[linked_key], "")]...
        )) :
        value
      )
    }
  }

  provider_custom_block_keys_by_provider = {
    for provider_name, provider_blocks in local.rendered_provider_custom_var_blocks :
    provider_name => keys(provider_blocks)
  }

  provider_custom_vars_default_merged = {
    for provider in var.module_providers :
    "${provider.name}${try(provider.alias, null) == null ? "" : "-${provider.alias}"}" => provider::deepmerge::mergo(
      try(provider.variables, {}),
      try(local.rendered_provider_custom_var_blocks[provider.name], {})
    )
  }

  providers_rendered = [
    for provider in var.module_providers : merge(provider, {
      alias = try(provider.alias, null)
      variables = {
        for key, value in try(provider.variables, {}) :
        key => (
          length(local.linked_setup_mapping) > 0 ?
          jsondecode(format(
            replace(replace(jsonencode(value), "%", "%%"), "/(${join("|", keys(local.linked_setup_mapping))})/", "%s"),
            [for linked_key in flatten(regexall("(${join("|", keys(local.linked_setup_mapping))})", replace(jsonencode(value), "%", "%%"))) : try(local.linked_setup_mapping[linked_key], "")]...
          )) :
          value
        )
        if !try(contains(local.provider_custom_block_keys_by_provider[provider.name], key), false)
      }
      blocks = {
        for key, value in try(provider.blocks, {}) :
        key => (
          length(local.linked_setup_mapping) > 0 ?
          jsondecode(format(
            replace(replace(jsonencode(value), "%", "%%"), "/(${join("|", keys(local.linked_setup_mapping))})/", "%s"),
            [for linked_key in flatten(regexall("(${join("|", keys(local.linked_setup_mapping))})", replace(jsonencode(value), "%", "%%"))) : try(local.linked_setup_mapping[linked_key], "")]...
          )) :
          value
        )
        if !try(contains(local.provider_custom_block_keys_by_provider[provider.name], key), false)
      }
      custom_var_blocks = {
        for key, value in merge(
          {
            for key, value in try(provider.custom_var_blocks, {}) :
            key => (
              length(local.linked_setup_mapping) > 0 ?
              jsondecode(format(
                replace(replace(jsonencode(value), "%", "%%"), "/(${join("|", keys(local.linked_setup_mapping))})/", "%s"),
                [for linked_key in flatten(regexall("(${join("|", keys(local.linked_setup_mapping))})", replace(jsonencode(value), "%", "%%"))) : try(local.linked_setup_mapping[linked_key], "")]...
              )) :
              value
            )
            if !try(contains(local.provider_custom_block_keys_by_provider[provider.name], key), false)
          },
          {
            for key, value in try(local.provider_custom_vars_default_merged["${provider.name}${try(provider.alias, null) == null ? "" : "-${provider.alias}"}"], {}) :
            key => value
            if try(contains(local.provider_custom_block_keys_by_provider[provider.name], key), false)
          }
        ) :
        key => (
          length(local.linked_setup_mapping) > 0 ?
          jsondecode(format(
            replace(replace(jsonencode(value), "%", "%%"), "/(${join("|", keys(local.linked_setup_mapping))})/", "%s"),
            [for linked_key in flatten(regexall("(${join("|", keys(local.linked_setup_mapping))})", replace(jsonencode(value), "%", "%%"))) : try(local.linked_setup_mapping[linked_key], "")]...
          )) :
          value
        )
      }
    })
  ]

  module_input_exact_expressions = {
    for key, value in var.module_vars :
    key => (
      length(local.linked_setup_mapping) > 0 ?
      format(
        replace(replace(replace(replace(tostring(value), "/^\\$\\{/", ""), "/\\}$/", ""), "%", "%%"), "/(${join("|", keys(local.linked_setup_mapping))})/", "%s"),
        [for linked_key in flatten(regexall("(${join("|", keys(local.linked_setup_mapping))})", replace(replace(replace(tostring(value), "/^\\$\\{/", ""), "/\\}$/", ""), "%", "%%"))) : try(local.linked_setup_mapping[linked_key], "")]...
      ) :
      replace(replace(tostring(value), "/^\\$\\{/", ""), "/\\}$/", "")
    )
    if can(regex("^\\$\\{[^}]+\\}$", value))
  }

  module_input_entries = [
    for key, value in var.module_vars : {
      key = key
      hcl = contains(keys(local.module_input_exact_expressions), key) ? local.module_input_exact_expressions[key] : replace(replace(jsonencode(value), "\\u003c", "<"), "\\u003e", ">")
    }
  ]

  module_providers_grouped = { for provider in var.module_providers : provider.name => provider... }
  versions_content = templatefile("${path.module}/templates/generated_versions.tf.tftpl", {
    note              = local.note
    terraform_version = var.terraform_version
    backend_name      = try(var.terraform_backend.name, null)
    providers = [for group in local.module_providers_grouped : {
      name                  = group[0].name
      version               = group[0].version
      source                = coalesce(try(group[0].source, null), "hashicorp/${group[0].name}")
      configuration_aliases = replace(jsonencode([for item in group : "${group[0].name}.${try(item.alias, null)}" if try(item.alias, null) != null]), "\"", "")
    }]
  })

  providers_content = templatefile("${path.module}/templates/generated_providers.tf.tftpl", {
    note      = local.note
    providers = local.providers_rendered
  })

  files_to_generate = [
    {
      name = "terragrunt.hcl"
      content = templatefile("${path.module}/templates/terragrunt.hcl.tftpl", {
        generated_by_module = var.generated_by_module
        note                = local.note
        name                = var.unit_name
        description         = var.unit_description
        terraform_source    = local.terraform_source
        dependencies        = local.linked_unit_configs
        inputs              = local.module_input_entries
        remote_state        = try(var.terraform_backend.name, null) == null ? null : var.terraform_backend
        generate_versions   = length(var.module_providers) > 0 || var.terraform_version != "" || try(var.terraform_backend.name, null) != null
        versions_content    = local.versions_content
        generate_providers  = length(local.providers_rendered) > 0
        providers_content   = local.providers_content
      })
    }
  ]
}
