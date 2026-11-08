resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = var.daily_quota_gb
  tags                = var.tags
}
resource "azurerm_monitor_metric_alert" "cpu" {
  count               = var.cluster_id == null ? 0 : 1
  name                = "${var.name}-node-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.cluster_id]
  description         = "Lab node CPU above 90 percent. Optional paid alert; no action group configured."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }
  tags = var.tags
}
