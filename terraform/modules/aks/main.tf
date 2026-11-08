resource "azurerm_kubernetes_cluster" "this" {
  #checkov:skip=CKV_AZURE_115:LAB-012 static-IP-restricted public API allows a personal lab without paid private-network agents
  #checkov:skip=CKV_AZURE_227:LAB-013 host-encryption subscription feature is not assumed; ephemeral lab nodes contain no persistent application data
  #checkov:skip=CKV_AZURE_170:LAB-014 Free management tier is explicit lab requirement and offers no production SLA
  #checkov:skip=CKV_AZURE_232:LAB-015 one shared system pool avoids paid additional user pool; namespaces are not production boundaries
  #checkov:skip=CKV_AZURE_171:LAB-016 exact Kubernetes patches are upgraded by reviewed Terraform plans instead of automatic version drift
  #checkov:skip=CKV_AZURE_116:LAB-017 Pod Security restricted admission and namespace quotas are enforced; Azure Policy addon is outside the minimal lab
  #checkov:skip=CKV_AZURE_117:LAB-018 ephemeral OS disk has no managed-disk encryption-set resource; production CMK design requires separate review
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.name
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = "Free"
  local_account_disabled            = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true
  node_os_upgrade_channel           = "NodeImage"
  node_provisioning_profile { mode = "Manual" }
  default_node_pool {
    name                        = "system"
    vm_size                     = var.vm_size
    node_count                  = 2
    vnet_subnet_id              = var.subnet_id
    os_sku                      = "Ubuntu"
    os_disk_type                = "Ephemeral"
    os_disk_size_gb             = 64
    max_pods                    = 50
    auto_scaling_enabled        = var.autoscaling_enabled
    min_count                   = var.autoscaling_enabled ? 2 : null
    max_count                   = var.autoscaling_enabled ? 3 : null
    temporary_name_for_rotation = "systemtemp"
    upgrade_settings { max_surge = "1" }
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
  }
  api_server_access_profile { authorized_ip_ranges = var.authorized_ip_ranges }
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
    outbound_type       = "loadBalancer"
    load_balancer_sku   = "standard"
    load_balancer_profile { managed_outbound_ip_count = 1 }
  }
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id == null ? [] : [var.log_analytics_workspace_id]
    content {
      log_analytics_workspace_id      = oms_agent.value
      msi_auth_for_monitoring_enabled = true
    }
  }
  tags = var.tags
}
