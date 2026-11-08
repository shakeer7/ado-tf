output "state_resource_group" { value = try(azurerm_resource_group.state[0].name, null) }
output "platform_resource_group" { value = try(azurerm_resource_group.platform[0].name, null) }
output "storage_account_name" { value = try(azurerm_storage_account.state[0].name, null) }
output "pipeline_client_ids" { value = { for k, v in module.pipeline_identity : k => v.client_id } }
output "admin_group_id" { value = try(azuread_group.aks_admins[0].object_id, null) }
output "pipeline_principal_ids" { value = { for k, v in module.pipeline_identity : k => v.principal_id } }
