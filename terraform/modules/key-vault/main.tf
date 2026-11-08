resource "azurerm_key_vault" "this" {
  #checkov:skip=CKV2_AZURE_32:LAB-019 service-endpoint subnet plus deny firewall and operator CIDRs avoid additional private endpoint cost
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = true
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = var.allowed_ip_cidrs
    virtual_network_subnet_ids = [var.subnet_id]
  }
  tags = var.tags
}
