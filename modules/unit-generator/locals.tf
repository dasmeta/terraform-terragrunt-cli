locals {
  unit_path_parts = split("/", var.unit_path)

  linked_unit_configs = [
    for linked_unit_path in var.linked_unit_paths : {
      name = replace(linked_unit_path, "/[^a-zA-Z0-9_-]+/", "_")
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
    }
  ]

  files_to_generate = [
    {
      name = "terragrunt.hcl"
      content = templatefile("${path.module}/templates/terragrunt.hcl.tftpl", {
        generated_by_module = var.generated_by_module
        name                = var.unit_name
        description         = var.unit_description
        dependencies        = local.linked_unit_configs
      })
    }
  ]
}
