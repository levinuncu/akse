locals {
  location = "westeurope"
  rg_name  = "rg-akse"
  pip_name = "pip-akse"
  kv_name  = "kv-akse"
  acr_name = "aksecr"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = local.location
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_public_ip" "pip" {
  name                = local.pip_name
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault" "kv" {
  name                       = local.kv_name
  location                   = local.location
  resource_group_name        = azurerm_resource_group.rg.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 90
  purge_protection_enabled   = false
  enable_rbac_authorization  = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_dns_zone" "zone" {
  name                = "pipgroup.de"
  resource_group_name = azurerm_resource_group.rg.name
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_dns_a_record" "root" {
  name                = "@"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  records             = [azurerm_public_ip.pip.ip_address]
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_dns_a_record" "wildcard" {
  name                = "*"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  records             = [azurerm_public_ip.pip.ip_address]
  lifecycle {
    prevent_destroy = true
  }
}