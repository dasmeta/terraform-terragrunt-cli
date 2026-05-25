module "this" {
  source = "../.."

  yamldir   = "${path.module}/example-infra"
  targetdir = "./output"
  terraform_backend = {
    name = "local"
    configs = {
      path = "./state"
    }
  }
}
