variable "generated_dir" {
  type        = string
  description = "Root output directory where the shared Terragrunt root config is written."
}

variable "generated_by_module" {
  type        = string
  description = "Module identifier written into generated files."
}
