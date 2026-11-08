output "cluster_name" { value = try(module.aks[0].name, null) }
output "cluster_id" { value = try(module.aks[0].id, null) }
output "node_resource_group" { value = try(module.aks[0].node_resource_group, null) }
output "acr_login_server" { value = try(module.acr[0].login_server, null) }
output "key_vault_name" { value = try(module.key_vault[0].name, null) }
output "workload_client_ids" { value = { for k, v in module.workload_identity : k => v.client_id } }
output "platform_resource_group" { value = var.resource_group_name }
output "node_count" { value = try(module.aks[0].node_count, null) }
