output "resource_group_name" {
  description = "Provisioned Azure Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  description = "Fully Qualified Domain Name of Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "production_hostname" {
  description = "Public URL for Production Web App"
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "staging_hostname" {
  description = "Public URL for Staging Slot"
  value       = "https://${azurerm_linux_web_app_slot.staging.default_hostname}"
}

output "managed_identity_principal_id" {
  description = "System-Assigned Managed Identity Principal ID for RBAC bindings"
  value       = azurerm_linux_web_app.backend.identity[0].principal_id
}

output "log_analytics_workspace_id" {
  description = "Azure Monitor Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.logs.id
}
