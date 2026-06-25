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
    name    = string            # Terraform backend type applied to generated Terragrunt units by default.
    configs = optional(any, {}) # Backend configuration arguments applied to generated Terragrunt units by default.
  })
  default     = { name = null, configs = null } # Null backend values mean no default backend block is rendered.
  description = "Optional default Terraform backend configuration applied to generated units."
}

variable "mock_outputs_enabled" {
  type        = bool
  default     = true
  description = "Whether Terragrunt dependency mock_outputs are enabled by default for consumer units. Individual unit YAML can override this with mock_outputs.enabled."
}

variable "provider_configs" {
  type = any
  default = {
    aws = {
      default_tags = {
        enabled      = true         # Enables automatic aws.default_tags rendering for generated units.
        managed_by   = "terraform"  # Value used for the ManagedBy default tag.
        applied_from = "terragrunt" # Value used for the AppliedFrom default tag.
        extra_tags   = {}           # Additional default tags merged into generated aws.default_tags content.
      }
      custom_var_blocks = {} # Optional additional provider-specific custom blocks merged into rendered provider configuration.
    }
  }
  description = "Optional grouped provider-specific configuration rendered into generated Terragrunt helper files."
}
