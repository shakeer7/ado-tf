resource "azurerm_role_assignment" "this" {
  scope                = var.scope
  role_definition_name = var.role_name
  principal_id         = var.principal_id
  principal_type       = var.principal_type
  condition            = var.condition
  condition_version    = var.condition == null ? null : "2.0"
}
