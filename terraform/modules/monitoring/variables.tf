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

variable "daily_quota_gb" {
  type        = number
  description = "daily quota gb"
  default     = 0.1
  validation {
    condition     = var.daily_quota_gb > 0
    error_message = "Quota must be positive; this is not a billing cap."
  }
}

variable "cluster_id" {
  default     = null
  type        = string
  description = "cluster id"
}
