variable "generated_dir" {
  type        = string
  description = "The directory where generated unit folders are written."
}

variable "unit_path" {
  type        = string
  description = "Relative generated unit path."
}

variable "unit_name" {
  type        = string
  description = "Normalized generated unit name."
}

variable "unit_description" {
  type        = string
  description = "Human-readable unit description."
}

variable "module_source" {
  type        = string
  description = "Terraform module source from the shared YAML model."
}

variable "module_version" {
  type        = string
  description = "Terraform module version from the shared YAML model."
}

variable "module_vars" {
  type        = any
  default     = {}
  description = "Module input variables from the shared YAML model."
}

variable "module_providers" {
  type        = any
  default     = []
  description = "Optional provider configuration declarations from the shared YAML model."
}

variable "linked_unit_paths" {
  type        = list(string)
  default     = []
  description = "Relative linked unit paths used for Terragrunt orchestration ordering."
}

variable "terraform_version" {
  type        = string
  description = "Terraform version constraint used for generated Terragrunt helper files."
}

variable "terraform_backend" {
  type = object({
    name    = string
    configs = optional(any, {})
  })
  description = "Optional backend configuration rendered as a Terragrunt remote_state block."
}

variable "provider_configs" {
  type        = any
  default     = {}
  description = "Optional grouped provider-specific configuration rendered into generated helper files."
}

variable "generated_by_module" {
  type        = string
  description = "Module identifier written into generated files."
}
