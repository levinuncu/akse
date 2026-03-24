resource "azurerm_role_assignment" "kv_secrets" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  lifecycle {
    prevent_destroy = true
  }
}