mock_provider "azurerm" {
  mock_resource "azurerm_kubernetes_cluster" {
    override_during = plan
    defaults = {
      oidc_issuer_url = "https://oidc.example.test/"
      kubelet_identity = [{
        client_id                 = "00000000-0000-0000-0000-000000000002"
        object_id                 = "00000000-0000-0000-0000-000000000003"
        user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/kubelet"
      }]
    }
  }
  mock_data "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
      name     = "test-rg"
      location = "centralindia"
    }
  }
}
variables {
  subscription_id        = "00000000-0000-0000-0000-000000000000"
  tenant_id              = "00000000-0000-0000-0000-000000000000"
  resource_group_name    = "test-rg"
  unique_suffix          = "test123"
  kubernetes_version     = "1.36.1"
  budget_start_date      = "2026-11-01T00:00:00Z"
  authorized_ip_ranges   = ["203.0.113.1/32"]
  admin_group_object_ids = ["00000000-0000-0000-0000-000000000001"]
  budget_emails          = ["lab@example.com"]
}
run "default_is_off" {
  command = plan
  assert {
    condition     = output.cluster_name == null && output.key_vault_name == null && output.acr_login_server == null
    error_message = "Azure resources must be absent by default."
  }
}
run "approval_required" {
  command = plan
  variables { enable_azure = true }
  expect_failures = [terraform_data.approval]
}
run "approved_minimal_shape" {
  command = plan
  variables {
    enable_azure        = true
    deployment_approved = true
    cost_acknowledged   = true
  }
  assert {
    condition     = output.node_count == 2 && output.acr_login_server == null
    error_message = "The approved Azure lab must use two system nodes and leave optional ACR disabled."
  }
}
