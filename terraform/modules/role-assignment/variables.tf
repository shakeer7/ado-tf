variable "scope" {
  type        = string
  description = "scope"
}

variable "role_name" {
  type        = string
  description = "role name"
}

variable "principal_id" {
  type        = string
  description = "principal id"
}

variable "principal_type" {
  type        = string
  description = "principal type"
  default     = "ServicePrincipal"
  validation {
    condition     = contains(["ServicePrincipal", "Group", "User"], var.principal_type)
    error_message = "Choose a valid principal type."
  }
}

variable "condition" {
  default     = null
  type        = string
  description = "condition"
}
