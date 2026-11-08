variable "name" {
  type        = string
  description = "name"
}

variable "location" {
  type        = string
  description = "location"
}

variable "resource_group_name" {
  type        = string
  description = "resource group name"
}

variable "tags" {
  type        = map(string)
  description = "tags"
  default     = {}
}

variable "kubernetes_version" {
  type        = string
  description = "kubernetes version"
}

variable "vm_size" {
  type        = string
  description = "vm size"
  default     = "Standard_D4ds_v5"
  validation {
    condition     = !startswith(var.vm_size, "Standard_B")
    error_message = "B-series is unsupported for system pools. Verify at least 4 vCPUs and regional availability."
  }
}

variable "subnet_id" {
  type        = string
  description = "subnet id"
}

variable "identity_id" {
  type        = string
  description = "identity id"
}

variable "tenant_id" {
  type        = string
  description = "tenant id"
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "admin group object ids"
}

variable "authorized_ip_ranges" {
  type        = set(string)
  description = "authorized ip ranges"
  validation {
    condition     = length(var.authorized_ip_ranges) > 0 && alltrue([for c in var.authorized_ip_ranges : can(cidrnetmask(c)) && c != "0.0.0.0/0"])
    error_message = "Provide explicit trusted public IPv4 CIDRs; world access is forbidden."
  }
}

variable "autoscaling_enabled" {
  type        = bool
  description = "autoscaling enabled"
  default     = false
}

variable "log_analytics_workspace_id" {
  default     = null
  type        = string
  description = "log analytics workspace id"
}
