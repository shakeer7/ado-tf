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

variable "cost_acknowledged" {
  type        = bool
  description = "cost acknowledged"
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

variable "resource_group_name" {
  type        = string
  description = "resource group name"
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

variable "unique_suffix" {
  type        = string
  description = "unique suffix"
  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.unique_suffix))
    error_message = "Use 3 to 8 lowercase letters and digits for global names."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "kubernetes version"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Select an exact GA patch returned by az aks get-versions for your region."
  }
}

variable "node_vm_size" {
  type        = string
  description = "node vm size"
  default     = "Standard_D4ds_v5"
}

variable "authorized_ip_ranges" {
  type        = set(string)
  description = "authorized ip ranges"
  default     = []
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "admin group object ids"
  default     = []
}

variable "enable_acr" {
  type        = bool
  description = "enable acr"
  default     = false
}

variable "enable_monitoring" {
  type        = bool
  description = "enable monitoring"
  default     = false
}

variable "enable_autoscaling" {
  type        = bool
  description = "enable autoscaling"
  default     = false
}

variable "budget_amount" {
  type        = number
  description = "budget amount"
  default     = 25
}

variable "budget_start_date" {
  type        = string
  description = "budget start date"
}

variable "budget_emails" {
  type        = list(string)
  description = "budget emails"
  default     = []
}

variable "app_pipeline_principal_id" {
  type        = string
  description = "app pipeline principal id"
  default     = ""
}

variable "aks_operator_principal_id" {
  type        = string
  description = "aks operator principal id"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "tags"
  default     = { project = "azure-platform-devops", owner = "personal-lab", purpose = "interview", expires = "review-before-deployment" }
}
