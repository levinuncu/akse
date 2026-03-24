output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "rg_id" {
  value = azurerm_resource_group.rg.id
}

output "location" {
  value = local.location
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "kv_id" {
  value = azurerm_key_vault.kv.id
}

output "kv_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "pip_name" {
  value = azurerm_public_ip.pip.name
}

output "domain" {
  value = azurerm_dns_zone.zone.name
}