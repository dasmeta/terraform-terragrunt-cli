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

variable "linked_unit_paths" {
  type        = list(string)
  default     = []
  description = "Relative linked unit paths used for Terragrunt orchestration ordering."
}

variable "generated_by_module" {
  type        = string
  description = "Module identifier written into generated files."
}
