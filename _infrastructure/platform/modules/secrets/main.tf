resource "azurerm_user_assigned_identity" "identity" {
  name                = "identity"
  location            = var.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_role_assignment" "kv_secrets" {
  scope                = var.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_federated_identity_credential" "external_secrets_operator" {
  name                = "external-secrets-operator-workload-identity"
  resource_group_name = var.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.identity.id
  subject             = "system:serviceaccount:${kubernetes_service_account.service_account.metadata[0].namespace}:${kubernetes_service_account.service_account.metadata[0].name}"
}

resource "kubernetes_namespace" "secrets" {
  metadata {
    name = "secrets"
  }
}

resource "kubernetes_service_account" "service_account" {
  metadata {
    name      = "external-secrets-operator-service-account"
    namespace = kubernetes_namespace.secrets.metadata[0].name
    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.identity.client_id,
      "azure.workload.identity/tenant-id" = azurerm_user_assigned_identity.identity.tenant_id
    }
    labels = {
      "azure.workload.identity/use" = "true"
    }
  }
}

resource "helm_release" "external_secrets_operator" {
  name       = "external-secrets-operator"
  namespace  = kubernetes_namespace.secrets.metadata[0].name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.15.1"
  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.service_account.metadata[0].name
      }
    })
  ]
}

resource "helm_release" "secret_store" {
  name                       = "secret-store"
  namespace                  = kubernetes_namespace.secrets.metadata[0].name
  chart                      = "./helm/secret-store"
  disable_openapi_validation = true
  values = [
    yamlencode({
      vaultUrl                = var.key_vault.vault_uri
      serviceAccountName      = kubernetes_service_account.service_account.metadata[0].name
      serviceAccountNamespace = kubernetes_service_account.service_account.metadata[0].namespace
    })
  ]
  depends_on = [azurerm_federated_identity_credential.external_secrets_operator, helm_release.external_secrets_operator]
}

resource "helm_release" "external_secret" {
  for_each = {
    for item in flatten([
      for secret in var.secrets : [
        for namespace in secret.namespaces : {
          key         = "${secret.name}-${namespace}"
          name        = secret.name
          namespace   = namespace
          target_type = secret.target_type
          target_data = secret.target_data
          data        = secret.data
        }
      ]
    ])
    : item.key => item
  }
  name             = each.value.name
  namespace        = each.value.namespace
  create_namespace = true
  chart            = "./helm/external-secret"
  values = [
    yamlencode(({
      secretStoreName = helm_release.secret_store.name
      secretName      = each.value.name
      targetType      = each.value.target_type
      targetData      = each.value.target_data
      data = [
        for secret in each.value.data : {
          secretKey = secret.secret_key
          remoteRef = {
            key = secret.remote_key
          }
        }
      ]
    }))
  ]
}

