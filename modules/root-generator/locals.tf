locals {
  files_to_generate = [
    {
      name    = "root.hcl"
      content = templatefile("${path.module}/templates/root.hcl.tftpl", { generated_by_module = var.generated_by_module })
    }
  ]
}
