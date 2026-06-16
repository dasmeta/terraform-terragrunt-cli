variable "generated_dir" {
  type        = string
  description = "Root output directory where the shared Terragrunt root config is written."
}

variable "generated_by_module" {
  type        = string
  description = "Module identifier written into generated files."
}

variable "note" {
  type        = string
  default     = "This file and its content are generated based on config, pleas check README.md for more details"
  description = "Note/comment text written at the top of generated Terragrunt root files."
}
