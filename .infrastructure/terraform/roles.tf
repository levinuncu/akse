resource "azurerm_user_assigned_identity" "identity" {
  name                = "identity"
  location            = var.location
  resource_group_name = module.rg.name
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.principal_id
}

resource "azurerm_role_assignment" "kv_secrets" {
  scope                = module.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}