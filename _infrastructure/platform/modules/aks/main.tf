resource "azurerm_kubernetes_cluster" "cluster" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resource_group.name
  dns_prefix                = "${var.name}-dns"
  sku_tier                  = "Standard"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_A2_v2"
  }
  identity {
    type = "SystemAssigned"
  }
  network_profile {
    network_plugin = "azure"
  }
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace.id
  }
  lifecycle {
    ignore_changes = [default_node_pool[0].upgrade_settings]
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
}