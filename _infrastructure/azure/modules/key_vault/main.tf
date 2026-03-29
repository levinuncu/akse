data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 90
  purge_protection_enabled   = false
  enable_rbac_authorization  = true
}

resource "random_password" "secret" {
  for_each = toset(var.secrets)
  length   = 32
  special  = false
}

resource "azurerm_key_vault_secret" "secret" {
  for_each     = toset(var.secrets)
  name         = each.value
  value        = random_password.secret[each.key].result
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on   = [azurerm_role_assignment.kv_secrets]
}

resource "azurerm_role_assignment" "kv_secrets" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
