resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${var.name}-workspace"
  location            = var.location
  resource_group_name = var.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "insights" {
  name                = "${var.name}-insights"
  location            = var.location
  resource_group_name = var.resource_group.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.workspace.id
}