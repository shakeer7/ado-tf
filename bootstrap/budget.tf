# Bootstrap permissions cover subscription cost governance. Recurring deployment
# identities do not receive rights on the separately generated AKS node RG.
variable "budget_amount" {
  type        = number
  default     = 25
  description = "Subscription monthly alert threshold in billing currency"
  validation {
    condition     = var.budget_amount > 0
    error_message = "Budget must be positive."
  }
}
variable "budget_start_date" {
  type        = string
  description = "First day of deployment month, e.g. 2026-11-01T00:00:00Z"
}
variable "budget_emails" {
  type        = list(string)
  default     = []
  description = "Alert contacts; mandatory when enabling Azure"
}
resource "azurerm_consumption_budget_subscription" "lab" {
  count           = var.enable_azure ? 1 : 0
  name            = "${var.prefix}-subscription-monthly"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"
  time_period { start_date = var.budget_start_date }
  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThanOrEqualTo"
    contact_emails = var.budget_emails
  }
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    contact_emails = var.budget_emails
  }
  lifecycle {
    precondition {
      condition     = length(var.budget_emails) > 0
      error_message = "Set an alert email; budgets never enforce a spending limit."
    }
  }
}
