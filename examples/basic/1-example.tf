module "this" {
  source = "../.."

  yamldir   = "${path.module}/example-infra"
  targetdir = "./output"
}
