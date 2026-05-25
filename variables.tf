variable "yamldir" {
  type        = string
  default     = "."
  description = "The directory where YAML module definitions are located."
}

variable "targetdir" {
  type        = string
  default     = "./generated/units"
  description = "The directory where generated Terragrunt units will be written."
}

variable "terraform_version" {
  type        = string
  default     = "~> 1.3"
  description = "The Terraform version constraint emitted into generated unit files."
}

variable "terraform_backend" {
  type = object({
    name    = string
    configs = optional(any, {})
  })
  default     = { name = null, configs = null }
  description = "Optional default Terraform backend configuration applied to generated units."
}

variable "provider_custom_var_blocks" {
  type        = any
  default     = {}
  description = "Optional provider-specific custom blocks passed to the shared renderer."
}

variable "provider_default_tags" {
  type = any
  default = {
    aws = {
      enabled      = true
      managed_by   = "terraform"
      applied_from = "terragrunt"
      extra_tags   = {}
    }
  }
  description = "Optional provider-specific default tag settings passed to the shared renderer."
}
