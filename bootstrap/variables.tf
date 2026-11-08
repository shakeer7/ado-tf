variable "enable_azure" {
  type        = bool
  description = "enable azure"
  default     = false
}

variable "deployment_approved" {
  type        = bool
  description = "deployment approved"
  default     = false
}

variable "subscription_id" {
  type        = string
  description = "subscription id"
}

variable "tenant_id" {
  type        = string
  description = "tenant id"
}

variable "location" {
  type        = string
  description = "location"
  default     = "centralindia"
}

variable "prefix" {
  type        = string
  description = "prefix"
  default     = "azplab"
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,9}$", var.prefix))
    error_message = "Use 3 to 10 lowercase letters and digits."
  }
}

variable "storage_account_name" {
  type        = string
  description = "storage account name"
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage name must be globally unique, 3 to 24 lowercase letters and digits."
  }
}

variable "allowed_ip_cidrs" {
  type        = set(string)
  description = "allowed ip cidrs"
  default     = []
}

variable "operator_object_id" {
  type        = string
  description = "operator object id"
}

variable "federations" {
  type        = map(object({ issuer = string, subject = string }))
  description = "federations"
  default     = {}
  validation {
    condition     = alltrue([for key in keys(var.federations) : contains(["plan", "apply", "destroy", "app"], key)])
    error_message = "Federation keys must be plan, apply, destroy or app; unknown keys cannot receive default privileges."
  }
}

variable "create_admin_group" {
  type        = bool
  description = "create admin group"
  default     = false
}

variable "admin_group_owners" {
  type        = set(string)
  description = "admin group owners"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "tags"
  default     = { project = "azure-platform-devops", owner = "personal-lab", purpose = "interview", expires = "review-before-deployment" }
}
