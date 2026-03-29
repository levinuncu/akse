output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}

output "container_registry_id" {
  value = module.acr.id
}

output "container_registry_login_server" {
  value = module.acr.login_server
}

output "key_vault_id" {
  value = module.key_vault.id
}

output "key_vault_vault_uri" {
  value = module.key_vault.vault_uri
}

output "public_ip_id" {
  value = azurerm_public_ip.pip.id
}

output "public_ip_name" {
  value = azurerm_public_ip.pip.name
}

output "postgres_disk_id" {
  value = azurerm_managed_disk.postgres_disk.id
}

output "postgres_disk_size" {
  value = azurerm_managed_disk.postgres_disk.disk_size_gb
}

output "log_analytics_workspace_id" {
  value = module.analytics.log_analytics_workspace_id
}

output "application_insights_connection_string" {
  value     = module.analytics.application_insights_connection_string
  sensitive = true
}

output "secret_keys" {
  value = local.secret_keys
}