# 1. Primary Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Project     = "Nyaga Law Practice Engine"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Compliance  = "Advocates-Remuneration-Order"
  }
}

# 2. Virtual Network for Isolated Cloud Workloads
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.app_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]

  tags = azurerm_resource_group.rg.tags
}

# 3. Dedicated Delegated Subnet for App Service Regional VNet Integration
resource "azurerm_subnet" "app_service_subnet" {
  name                 = "snet-appservice-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_subnet_cidr]

  delegation {
    name = "appservice-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# 4. Network Security Group (NSG) with Hardened Access Rules
resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-${var.app_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow inbound HTTPS (Port 443)
  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Deny unencrypted cleartext HTTP traffic
  security_rule {
    name                       = "Deny-HTTP-Cleartext"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.rg.tags
}
