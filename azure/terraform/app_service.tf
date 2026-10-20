# 1. Linux Compute Plan
resource "azurerm_service_plan" "plan" {
  name                = "plan-${var.app_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = azurerm_resource_group.rg.tags
}

# 2. Production Web App for Containers
resource "azurerm_linux_web_app" "backend" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true

  # Regional VNet Integration
  virtual_network_subnet_id = azurerm_subnet.app_service_subnet.id

  # Security: System-Assigned Managed Identity for Passwordless Azure Access
  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                           = true
    http2_enabled                       = true
    minimum_tls_version                 = "1.2"
    health_check_path                   = "/api/v1/health"
    health_check_eviction_time_in_min   = 5
    vnet_route_all_enabled              = true

    application_stack {
      docker_image_name   = "karani-backend:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }

    # Restrict cleartext administration
    ftps_state = "Disabled"
  }

  app_settings = {
    "WEBSITES_PORT"                       = "8000"
    "PORT"                                = "8000"
    "APP_ENV"                             = "production"
    "DOCKER_ENABLE_CI"                    = "true"
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = azurerm_application_insights.app_insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app_insights.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }

  tags = azurerm_resource_group.rg.tags
}

# 3. Staging Deployment Slot for Blue/Green Zero-Downtime Rollouts
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.backend.id
  https_only     = true

  # Inherits VNet integration
  virtual_network_subnet_id = azurerm_subnet.app_service_subnet.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                         = false
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    health_check_path                 = "/api/v1/health"
    health_check_eviction_time_in_min = 5

    application_stack {
      docker_image_name   = "karani-backend:staging"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }

    ftps_state = "Disabled"
  }

  app_settings = {
    "WEBSITES_PORT"  = "8000"
    "PORT"           = "8000"
    "APP_ENV"        = "staging"
  }

  tags = azurerm_resource_group.rg.tags
}
