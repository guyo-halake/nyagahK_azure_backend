# Azure Container Registry (ACR) with System-Assigned Managed Identity RBAC
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false # Security Best Practice: Admin credentials disabled in favor of Managed Identity

  tags = azurerm_resource_group.rg.tags
}

# Role Assignment: Grants App Service Managed Identity permissions to pull images from ACR
resource "azurerm_role_assignment" "acr_pull_prod" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.backend.identity[0].principal_id
}

resource "azurerm_role_assignment" "acr_pull_staging" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app_slot.staging.identity[0].principal_id
}
