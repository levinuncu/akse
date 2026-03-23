resource "azurerm_federated_identity_credential" "eso" {
  name                = "eso-wi"
  resource_group_name = module.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.identity.id
  subject             = "system:serviceaccount:${kubernetes_service_account.eso_akv_sa.metadata[0].namespace}:${kubernetes_service_account.eso_akv_sa.metadata[0].name}"
}

resource "kubernetes_service_account" "eso_akv_sa" {
  metadata {
    name      = "eso-akv-sa"
    namespace = "default"
    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.identity.client_id,
      "azure.workload.identity/tenant-id" = azurerm_user_assigned_identity.identity.tenant_id
    }
    labels = {
      "azure.workload.identity/use" = "true"
    }
  }
  depends_on = [module.aks]
}

