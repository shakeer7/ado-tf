resource "azurerm_monitor_metric_alert" "node_cpu" {
  count               = local.enabled && var.enable_monitoring ? 1 : 0
  name                = "${var.prefix}-node-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [module.aks[0].id]
  description         = "Optional paid lab CPU alert. No notification action group is configured."
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
  tags = local.tags
}
