variable "name" {
  type        = string
  description = "name"
}

variable "resource_group_id" {
  type        = string
  description = "resource group id"
}

variable "monthly_amount" {
  type        = number
  description = "monthly amount"
  default     = 25
  validation {
    condition     = var.monthly_amount > 0
    error_message = "Use a positive monthly budget in billing currency."
  }
}

variable "start_date" {
  type        = string
  description = "start date"
  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.start_date))
    error_message = "Use the first day of the current billing month in UTC."
  }
}

variable "contact_emails" {
  type        = list(string)
  description = "contact emails"
  validation {
    condition     = length(var.contact_emails) > 0
    error_message = "Provide a budget alert email."
  }
}
