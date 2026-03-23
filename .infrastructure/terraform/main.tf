data "azurerm_client_config" "current" {}

module "rg" {
  source   = "./modules/rg"
  name     = var.rg_name
  location = var.location
}

module "acr" {
  source              = "./modules/acr"
  name                = var.acr_name
  location            = var.location
  resource_group_name = module.rg.name
}

module "aks" {
  source              = "./modules/aks"
  name                = var.aks_name
  location            = var.location
  resource_group_name = module.rg.name
}

module "kv" {
  source              = "./modules/kv"
  name                = var.kv_name
  location            = var.location
  resource_group_name = module.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
}