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

variable "tenant_id" {
  type        = string
  description = "tenant id"
}

variable "subnet_id" {
  type        = string
  description = "subnet id"
}

variable "allowed_ip_cidrs" {
  type        = list(string)
  description = "allowed ip cidrs"
  default     = []
}
