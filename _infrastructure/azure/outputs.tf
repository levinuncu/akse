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

output "law_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "ai_connection_string" {
  value     = azurerm_application_insights.ai.connection_string
  sensitive = true
}

output "pg_disk_name" {
  value = azurerm_managed_disk.pg_disk.name
}

output "pg_disk_id" {
  value = azurerm_managed_disk.pg_disk.id
}

output "pg_disk_size" {
  value = azurerm_managed_disk.pg_disk.disk_size_gb
}