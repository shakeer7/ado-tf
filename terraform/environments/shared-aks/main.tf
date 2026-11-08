locals {
  enabled = var.enable_azure
  tags    = merge(var.tags, { environment = "shared-lab", managed_by = "terraform" })
}
resource "terraform_data" "approval" {
  input = local.enabled
  lifecycle {
    precondition {
      condition     = !local.enabled || (var.deployment_approved && var.cost_acknowledged && length(var.authorized_ip_ranges) > 0 && length(var.admin_group_object_ids) > 0 && length(var.budget_emails) > 0)
      error_message = "Azure requires explicit deployment and cost approval, API CIDRs, administrator group and budget email."
    }
  }
}
data "azurerm_resource_group" "platform" {
  count = local.enabled ? 1 : 0
  name  = var.resource_group_name
}
module "networking" {
  count               = local.enabled ? 1 : 0
  source              = "../../modules/networking"
  name                = "${var.prefix}-vnet"
  location            = data.azurerm_resource_group.platform[0].location
  resource_group_name = var.resource_group_name
  tags                = local.tags
  depends_on          = [terraform_data.approval]
}
module "cluster_identity" {
  count               = local.enabled ? 1 : 0
  source              = "../../modules/managed-identity"
  name                = "${var.prefix}-cluster"
  location            = data.azurerm_resource_group.platform[0].location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}
module "network_role" {
  count        = local.enabled ? 1 : 0
  source       = "../../modules/role-assignment"
  scope        = module.networking[0].subnet_id
  role_name    = "Network Contributor"
  principal_id = module.cluster_identity[0].principal_id
}
module "monitoring" {
  count               = local.enabled && var.enable_monitoring ? 1 : 0
  source              = "../../modules/monitoring"
  name                = "${var.prefix}-logs"
  location            = data.azurerm_resource_group.platform[0].location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}
module "aks" {
  count                      = local.enabled ? 1 : 0
  source                     = "../../modules/aks"
  name                       = "${var.prefix}-aks"
  location                   = data.azurerm_resource_group.platform[0].location
  resource_group_name        = var.resource_group_name
  subnet_id                  = module.networking[0].subnet_id
  identity_id                = module.cluster_identity[0].id
  tenant_id                  = var.tenant_id
  vm_size                    = var.node_vm_size
  kubernetes_version         = var.kubernetes_version
  authorized_ip_ranges       = var.authorized_ip_ranges
  admin_group_object_ids     = var.admin_group_object_ids
  autoscaling_enabled        = var.enable_autoscaling
  log_analytics_workspace_id = try(module.monitoring[0].workspace_id, null)
  tags                       = local.tags
  depends_on                 = [module.network_role, terraform_data.approval]
}
module "acr" {
  count               = local.enabled && var.enable_acr ? 1 : 0
  source              = "../../modules/acr"
  name                = "${var.prefix}${var.unique_suffix}"
  location            = data.azurerm_resource_group.platform[0].location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}
module "acr_pull" {
  count        = local.enabled && var.enable_acr ? 1 : 0
  source       = "../../modules/role-assignment"
  scope        = module.acr[0].id
  role_name    = "AcrPull"
  principal_id = module.aks[0].kubelet_object_id
}
resource "azurerm_role_assignment" "acr_push" {
  count                = local.enabled && var.enable_acr && var.app_pipeline_principal_id != "" ? 1 : 0
  scope                = module.acr[0].id
  role_definition_name = "AcrPush"
  principal_id         = var.app_pipeline_principal_id
}
module "key_vault" {
  count               = local.enabled ? 1 : 0
  source              = "../../modules/key-vault"
  name                = "${var.prefix}-${var.unique_suffix}-kv"
  location            = data.azurerm_resource_group.platform[0].location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  subnet_id           = module.networking[0].subnet_id
  allowed_ip_cidrs    = tolist(var.authorized_ip_ranges)
  tags                = local.tags
}
module "workload_identity" {
  for_each            = local.enabled ? toset(["dev", "stage"]) : toset([])
  source              = "../../modules/managed-identity"
  name                = "${var.prefix}-app-${each.key}"
  location            = data.azurerm_resource_group.platform[0].location
  resource_group_name = var.resource_group_name
  federations = {
    kubernetes = { issuer = module.aks[0].oidc_issuer_url, subject = "system:serviceaccount:${each.key}:sample-application" }
  }
  tags = local.tags
}
module "secret_reader" {
  for_each     = module.workload_identity
  source       = "../../modules/role-assignment"
  scope        = module.key_vault[0].id
  role_name    = "Key Vault Secrets User"
  principal_id = each.value.principal_id
}
resource "azurerm_role_assignment" "aks_operator" {
  count                = local.enabled && var.aks_operator_principal_id != "" ? 1 : 0
  scope                = module.aks[0].id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.aks_operator_principal_id
}
module "budget" {
  count             = local.enabled ? 1 : 0
  source            = "../../modules/cost-budget"
  name              = "${var.prefix}-monthly"
  resource_group_id = data.azurerm_resource_group.platform[0].id
  monthly_amount    = var.budget_amount
  start_date        = var.budget_start_date
  contact_emails    = var.budget_emails
}
