mock_provider "azurerm" {}
variables {
  name                = "testregistry123"
  location            = "centralindia"
  resource_group_name = "test-rg"
}
run "secure_acr" {
  command = plan
  assert {
    condition     = azurerm_container_registry.this.admin_enabled == false && azurerm_container_registry.this.sku == "Basic"
    error_message = "Lab ACR must use Basic and disable admin credentials."
  }
}
