resource "terraform_data" "approval" {
  input = var.enable_azure
  lifecycle {
    precondition {
      condition     = !var.enable_azure || (var.deployment_approved && length(var.allowed_ip_cidrs) > 0 && alltrue([for c in var.allowed_ip_cidrs : can(cidrnetmask(c)) && c != "0.0.0.0/0"]))
      error_message = "Explicit deployment approval and restricted storage firewall CIDRs are required."
    }
  }
}
resource "azurerm_resource_group" "state" {
  count    = var.enable_azure ? 1 : 0
  name     = "${var.prefix}-state-rg"
  location = var.location
  tags     = var.tags
  lifecycle { prevent_destroy = true }
}
resource "azurerm_resource_group" "platform" {
  count    = var.enable_azure ? 1 : 0
  name     = "${var.prefix}-platform-rg"
  location = var.location
  tags     = var.tags
  lifecycle { prevent_destroy = true }
}
resource "azurerm_storage_account" "state" {
  #checkov:skip=CKV2_AZURE_33:LAB-001 restricted public endpoint avoids paid private endpoint; migrate for production
  #checkov:skip=CKV2_AZURE_1:LAB-002 Azure-managed encryption avoids billable CMK dependencies; state access is RBAC protected
  count                           = var.enable_azure ? 1 : 0
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.state[0].name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  public_network_access           = "Enabled"
  network_rules {
    default_action = "Deny"
    bypass         = ["None"]
    ip_rules       = toset([for c in var.allowed_ip_cidrs : endswith(c, "/32") ? cidrhost(c, 0) : c])
  }
  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 14 }
    container_delete_retention_policy { days = 14 }
  }
  tags = var.tags
  lifecycle { prevent_destroy = true }
  depends_on = [terraform_data.approval]
}
resource "azurerm_role_assignment" "operator_state" {
  count                = var.enable_azure ? 1 : 0
  scope                = azurerm_storage_account.state[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.operator_object_id
}
resource "azurerm_storage_container" "state" {
  #checkov:skip=CKV2_AZURE_21:LAB-003 blob data-plane diagnostics require separately approved ingestion cost
  count                 = var.enable_azure ? 1 : 0
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state[0].id
  container_access_type = "private"
  lifecycle { prevent_destroy = true }
  depends_on = [azurerm_role_assignment.operator_state]
}
resource "azurerm_storage_container" "bootstrap" {
  #checkov:skip=CKV2_AZURE_21:LAB-003 blob data-plane diagnostics require separately approved ingestion cost
  count                 = var.enable_azure ? 1 : 0
  name                  = "bootstrap-state"
  storage_account_id    = azurerm_storage_account.state[0].id
  container_access_type = "private"
  lifecycle { prevent_destroy = true }
  depends_on = [azurerm_role_assignment.operator_state]
}
resource "azurerm_management_lock" "state" {
  count      = var.enable_azure ? 1 : 0
  name       = "protect-terraform-state"
  scope      = azurerm_resource_group.state[0].id
  lock_level = "CanNotDelete"
  notes      = "Backend deletion requires an independent approved recovery and retention review."
  lifecycle { prevent_destroy = true }
}
module "pipeline_identity" {
  for_each = var.enable_azure ? var.federations : {}
  source   = "../terraform/modules/managed-identity"
  name     = "${var.prefix}-${each.key}"
  # Recurring Contributor identities must not be able to edit their own federation.
  resource_group_name = azurerm_resource_group.state[0].name
  location            = var.location
  federations         = { devops = each.value }
  tags                = var.tags
}
resource "azurerm_role_assignment" "pipeline_arm" {
  for_each             = module.pipeline_identity
  scope                = azurerm_resource_group.platform[0].id
  role_definition_name = each.key == "plan" ? "Reader" : each.key == "app" ? "Reader" : "Contributor"
  principal_id         = each.value.principal_id
}
resource "azurerm_role_assignment" "pipeline_state" {
  for_each             = { for k, v in module.pipeline_identity : k => v if k != "app" }
  scope                = "${azurerm_storage_account.state[0].id}/blobServices/default/containers/${azurerm_storage_container.state[0].name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.principal_id
}
locals {
  delegated_role_ids = [
    "4d97b98b-1d4f-4787-a291-c67834d212e7", # Network Contributor
    "7f951dda-4ed3-4680-a7ca-43fe172d538d", # AcrPull
    "b86a8fe4-44ce-4948-aee5-eccb2c155cd7", # Key Vault Secrets User
    "8311e382-0749-4cb8-b61a-304f252e45ec", # AcrPush
    "b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b"  # AKS RBAC Cluster Admin
  ]
  allowed_role_ids = join(", ", local.delegated_role_ids)
}
resource "azurerm_role_assignment" "pipeline_delegation" {
  for_each             = { for k, v in module.pipeline_identity : k => v if contains(["apply", "destroy"], k) }
  scope                = azurerm_resource_group.platform[0].id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = each.value.principal_id
  condition_version    = "2.0"
  condition            = <<-CONDITION
  ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.allowed_role_ids}}))
  AND
  ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${local.allowed_role_ids}}))
  CONDITION
}
resource "azuread_group" "aks_admins" {
  count            = var.enable_azure && var.create_admin_group ? 1 : 0
  display_name     = "${var.prefix}-aks-admins"
  security_enabled = true
  owners           = var.admin_group_owners
}
