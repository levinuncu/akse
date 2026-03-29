locals {
  secret_keys = {
    rabbitmq = {
      password = "rabbitmq-password"
      username = "rabbitmq-username"
      cookie   = "rabbitmq-cookie"
    }
    postgres = {
      password = "postgres-password"
      username = "postgres-username"
    }
    keycloak = {
      password = "keycloak-password"
      secret   = "keycloak-secret"
    }
    tls_certificate = "pipgroup-tls"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-akse"
  location = "westeurope"
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-akse"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_managed_disk" "postgres_disk" {
  name                 = "postgres_disk-akse"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20
}

module "acr" {
  source   = "./modules/acr"
  name     = "aksecr"
  location = azurerm_resource_group.rg.location
  resource_group = {
    name = azurerm_resource_group.rg.name
  }
}

module "key_vault" {
  source   = "./modules/key_vault"
  name     = "kv-akse"
  location = azurerm_resource_group.rg.location
  resource_group = {
    name = azurerm_resource_group.rg.name
  }
  secrets = [
    local.secret_keys.postgres.password,
    local.secret_keys.postgres.username,
    local.secret_keys.rabbitmq.password,
    local.secret_keys.rabbitmq.username,
    local.secret_keys.rabbitmq.cookie,
    local.secret_keys.keycloak.password,
    local.secret_keys.keycloak.secret
  ]
}

module "dns" {
  source = "./modules/dns"
  name   = "pipgroup.de"
  resource_group = {
    name = azurerm_resource_group.rg.name
  }
  ip_address = azurerm_public_ip.pip.ip_address
}

module "certificate" {
  source = "./modules/certificate"
  email  = "levin@uncu.de"
  resource_group = {
    name = azurerm_resource_group.rg.name
  }
  dns_zone = {
    name = module.dns.dns_zone_name
  }
  key_vault = {
    id = module.key_vault.id
  }
  certificate_secret = local.secret_keys.tls_certificate
  depends_on         = [module.dns]
}

module "analytics" {
  source   = "./modules/analytics"
  name     = "akse-analytics"
  location = azurerm_resource_group.rg.location
  resource_group = {
    name = azurerm_resource_group.rg.name
  }
}
