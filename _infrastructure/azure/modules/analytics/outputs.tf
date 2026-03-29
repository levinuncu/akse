output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.workspace.id
}

output "application_insights_connection_string" {
  value = azurerm_application_insights.insights.connection_string
}