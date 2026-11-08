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

variable "vnet_cidr" {
  type        = string
  description = "vnet cidr"
  default     = "10.40.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vnet_cidr))
    error_message = "Use an IPv4 CIDR."
  }
}

variable "subnet_cidr" {
  type        = string
  description = "subnet cidr"
  default     = "10.40.0.0/24"
  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "Use an IPv4 CIDR."
  }
}
