# 1. Centralized Log Analytics Workspace for Container Logs
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-${var.app_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = azurerm_resource_group.rg.tags
}

# 2. Application Insights for APM, Request Tracing & Structured Telemetry
resource "azurerm_application_insights" "app_insights" {
  name                = "appi-${var.app_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"

  tags = azurerm_resource_group.rg.tags
}

# 3. Diagnostic Settings: Stream Web App HTTP & Console Logs to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "web_app_diagnostics" {
  name                       = "diag-${var.app_name}"
  target_resource_id         = azurerm_linux_web_app.backend.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# 4. SRE Reliability Alert: HTTP 5xx Server Errors (Sev 1)
resource "azurerm_monitor_metric_alert" "alert_5xx" {
  name                = "alert-high-5xx-errors"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_web_app.backend.id]
  description         = "Triggered when backend returns more than 5 server 5xx errors within 5 minutes"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  tags = azurerm_resource_group.rg.tags
}

# 5. SRE Reliability Alert: High CPU Consumption (Sev 2)
resource "azurerm_monitor_metric_alert" "alert_cpu" {
  name                = "alert-high-cpu-utilization"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_service_plan.plan.id]
  description         = "Triggered when App Service Plan CPU exceeds 85% sustained for 5 minutes"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  tags = azurerm_resource_group.rg.tags
}
