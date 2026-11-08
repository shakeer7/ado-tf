output "id" { value = azurerm_kubernetes_cluster.this.id }
output "name" { value = azurerm_kubernetes_cluster.this.name }
output "oidc_issuer_url" { value = azurerm_kubernetes_cluster.this.oidc_issuer_url }
output "kubelet_object_id" { value = one(azurerm_kubernetes_cluster.this.kubelet_identity[*].object_id) }
output "node_resource_group" { value = azurerm_kubernetes_cluster.this.node_resource_group }
output "node_count" { value = azurerm_kubernetes_cluster.this.default_node_pool[0].node_count }
