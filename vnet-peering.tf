variable "sec_sub_id" {
  type = string
  default="04ea53c9-4757-41b3-a7f4-c26f6f1b8b81"
}

variable "sec_client_id" {
  type = string
  default = "eee491d1-54f9-440f-aaf7-d7f270917fa1"
}

variable "sec_client_secret" {
  type = string
  default = "kP=YYO]XMR(DYvQW"
}

variable "sec_tenant_id" {
  type = string
    default = "7dc7b50b-f1da-44e6-82c0-f7e4245f04e9"
}

variable "sec_vnet_name" {
  type = string
  default="security"
}

variable "sec_vnet_id" {
  type = string
  default = "168129ef-48dc-4dc8-82ce-36780f747085"
}

variable "sec_resource_group" {
  type = string
  default="security"
}

variable "sec_principal_id" {
  type = string
  default = "474ede1b-4e90-42f7-85c7-2da417018dd5"
}


data "azurerm_subscription" "current" {}


provider "azurerm" {
  alias                       = "security"
  subscription_id             = var.sec_sub_id
  client_id                   = var.sec_client_id
  client_secret               = var.sec_client_secret
  tenant_id                   = var.sec_tenant_id
  skip_provider_registration  = true
  skip_credentials_validation = true
  features {}
}

provider "azurerm" {
  alias                       = "peering"
  subscription_id             = data.azurerm_subscription.current.subscription_id
  client_id                   = var.sec_client_id
  client_secret               = var.sec_client_secret
  tenant_id                   = data.azurerm_subscription.current.tenant_id
  skip_provider_registration  = true
  skip_credentials_validation = true
  features {}
}

resource "azurerm_role_definition" "vnet-peering" {
  name  = "allow-vnet-peer-main"
  scope = data.azurerm_subscription.current.id

  permissions {
    actions     = ["Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write", "Microsoft.Network/virtualNetworks/peer/action", "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read", "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id,
  ]
}

resource "azurerm_role_assignment" "vnet" {
  scope              = module.vnet-main.vnet_id
  role_definition_id = azurerm_role_definition.vnet-peering.role_definition_resource_id
  principal_id       = var.sec_principal_id
}

resource "azurerm_virtual_network_peering" "main" {
  name                      = "main_2_sec"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = module.vnet-main.vnet_name
  remote_virtual_network_id = var.sec_vnet_id
  provider                  = azurerm.peering

  depends_on = [azurerm_role_assignment.vnet]
}

resource "azurerm_virtual_network_peering" "sec" {
  name                      = "sec_2_main"
  resource_group_name       = var.sec_resource_group
  virtual_network_name      = var.sec_vnet_name
  remote_virtual_network_id = module.vnet-main.vnet_id
  provider                  = azurerm.security

  depends_on = [azurerm_role_assignment.vnet]
}