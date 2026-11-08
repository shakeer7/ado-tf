resource "azurerm_container_registry" "this" {
  #checkov:skip=CKV_AZURE_163:LAB-004 paid Defender replaced by blocking Trivy image scan before push
  #checkov:skip=CKV_AZURE_237:LAB-005 dedicated data endpoints require Premium; Basic lab registry is optional
  #checkov:skip=CKV_AZURE_166:LAB-006 quarantine workflow replaced by CI scan gate and reviewed digest release
  #checkov:skip=CKV_AZURE_167:LAB-007 retention automation requires a reviewed supported SKU; operator inventories images before manual cleanup
  #checkov:skip=CKV_AZURE_233:LAB-008 single-region Basic lab has no zone-redundancy requirement
  #checkov:skip=CKV_AZURE_165:LAB-009 no multi-region deployment; geo-replication adds cost
  #checkov:skip=CKV_AZURE_139:LAB-010 Basic public registry uses Entra RBAC and disabled admin/anonymous access; private endpoints require Premium
  #checkov:skip=CKV_AZURE_164:LAB-011 signatures are not implemented in this lab; scanned immutable digests and protected release PRs mitigate substitution
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "Basic"
  admin_enabled                 = false
  anonymous_pull_enabled        = false
  public_network_access_enabled = true
  tags                          = var.tags
}
