resource "local_file" "generated_files" {
  for_each = {
    for file in local.files_to_generate :
    file.name => file
  }

  filename = "${trimsuffix(var.generated_dir, "/")}/${var.unit_path}/${each.value.name}"
  content  = each.value.content
}
