# ==============================================================================
# Terraform Cloud Infrastructure: Microsoft Azure (azurerm provider)
# Provisions: Resource Group, ACR, Linux App Service Plan, Web App & Staging Slot
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-nyagahfee"
}

variable "app_name" {
  type    = string
  default = "nyagahkithinji-advocates"
}

// 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Production"
    Project     = "Nyaga Law Remuneration Engine"
    ManagedBy   = "Terraform"
  }
}

// 2. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "acrnyagahfee"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

// 3. Linux App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "plan-${var.app_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

// 4. Linux Web App for Containers (Production)
resource "azurerm_linux_web_app" "app" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true

  site_config {
    always_on         = true
    health_check_path = "/api/v1/health"

    application_stack {
      docker_image_name   = "karani-backend:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }

  app_settings = {
    "PORT"           = "8000"
    "WEBSITES_PORT"  = "8000"
    "APP_ENV"        = "production"
  }
}

// 5. Staging Slot for Zero-Downtime Blue/Green Deployment
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.app.id

  site_config {
    always_on         = false
    health_check_path = "/api/v1/health"

    application_stack {
      docker_image_name   = "karani-backend:staging"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }
}

output "acr_server" {
  value = azurerm_container_registry.acr.login_server
}

output "production_hostname" {
  value = azurerm_linux_web_app.app.default_hostname
}

output "staging_hostname" {
  value = azurerm_linux_web_app_slot.staging.default_hostname
}
