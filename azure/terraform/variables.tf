variable "environment" {
  type        = string
  description = "Target deployment environment (develop, staging, production)"
  default     = "production"
}

variable "location" {
  type        = string
  description = "Azure region for primary infrastructure deployment"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the central Azure Resource Group"
  default     = "rg-nyagahfee-prod"
}

variable "app_name" {
  type        = string
  description = "Base naming prefix for App Service and associated services"
  default     = "nyagahkithinji-advocates"
}

variable "acr_name" {
  type        = string
  description = "Globally unique name for the Azure Container Registry"
  default     = "acrnyagahfee"
}

variable "app_service_sku" {
  type        = string
  description = "Linux App Service Plan compute SKU tier"
  default     = "B1"
}

variable "vnet_cidr" {
  type        = string
  description = "Address space for virtual network"
  default     = "10.10.0.0/16"
}

variable "app_subnet_cidr" {
  type        = string
  description = "Subnet allocated for App Service Regional VNet Integration"
  default     = "10.10.1.0/24"
}
