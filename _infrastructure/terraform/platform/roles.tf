resource "azurerm_user_assigned_identity" "identity" {
  name                = "identity"
  location            = data.terraform_remote_state.azure.outputs.location
  resource_group_name = data.terraform_remote_state.azure.outputs.rg_name
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = data.terraform_remote_state.azure.outputs.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                            = data.terraform_remote_state.azure.outputs.rg_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "kv_secrets" {
  scope                = data.terraform_remote_state.azure.outputs.kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

