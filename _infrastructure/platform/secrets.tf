resource "azurerm_federated_identity_credential" "eso" {
  name                = "eso-wi"
  resource_group_name = data.terraform_remote_state.azure.outputs.rg_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
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
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "helm_release" "external_secrets_operator" {
  name       = "external-secrets-operator"
  namespace  = "default"
  repository = "https://charts.external-secrets.io"
  version    = "0.15.1"
  chart      = "external-secrets"
  values = [
    yamlencode({
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.eso_akv_sa.metadata[0].name
      }
    })
  ]
  depends_on = [azurerm_role_assignment.kv_secrets]
}

resource "helm_release" "secret_store" {
  name                       = "secret-store"
  chart                      = "../helm/secret-store"
  disable_openapi_validation = true
  values = [
    yamlencode({
      vaultUrl           = data.terraform_remote_state.azure.outputs.kv_vault_uri
      serviceAccountName = kubernetes_service_account.eso_akv_sa.metadata[0].name
    })
  ]
  depends_on = [helm_release.external_secrets_operator, azurerm_role_assignment.kv_secrets]
}
