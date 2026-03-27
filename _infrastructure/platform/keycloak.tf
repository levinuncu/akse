data "azurerm_key_vault_secret" "keycloak_secret" {
  name         = "keycloak-secret"
  key_vault_id = data.terraform_remote_state.azure.outputs.kv_id
}

resource "helm_release" "keycloak_secret" {
  name                       = "keycloak-secret"
  chart                      = "../helm/external-secret"
  disable_openapi_validation = true
  values = [
    yamlencode({
      name            = "keycloak-secret"
      secretStoreName = helm_release.secret_store.name
      data = [
        { secretKey = "password", remoteRef = { key = "keycloak-password" } },
        { secretKey = "secret", remoteRef = { key = "keycloak-secret" } },
      ]
    })
  ]
  depends_on = [helm_release.external_secrets_operator, azurerm_role_assignment.kv_secrets]
}

resource "helm_release" "keycloak" {
  name    = "keycloak"
  chart   = "oci://registry-1.docker.io/cloudpirates/keycloak"
  version = "0.19.7"
  values = [
    yamlencode({
      ingress = {
        enabled   = true
        className = "nginx"
        annotations = {
          "nginx.ingress.kubernetes.io/rewrite-target" = "/"
          "cert-manager.io/cluster-issuer"             = helm_release.cert_issuer.name
        }
        hosts = [
          {
            host = local.keycloak_host
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
        tls = [
          {
            secretName = local.tls_secret_name
            hosts      = [local.keycloak_host]
          }
        ]
      }
      keycloak = {
        existingSecret = helm_release.keycloak_secret.name
        secretKeys = {
          adminPasswordKey = "password"
        }
      }
      postgres = {
        enabled = false
      }
      database = {
        type           = "postgres"
        host           = "${helm_release.postgres.name}.${helm_release.postgres.namespace}.svc.cluster.local"
        port           = tostring(local.postgres_port)
        name           = local.postgres_database
        existingSecret = helm_release.postgres_secret.name
        secretKeys = {
          passwordKey = "password"
          usernameKey = "username"
        }
      }
      realm = {
        import = true
        configFile = templatefile("${path.module}/../../keycloak/prod-realm.json.tpl", {
          REALM        = local.keycloak_realm
          CLIENT_ID    = local.keycloak_client_id
          SECRET       = data.azurerm_key_vault_secret.keycloak_secret.value
          REDIRECT_URI = "https://identity.${data.terraform_remote_state.azure.outputs.domain}/service/identity/v1/api/auth/callback"
          WEB_ORIGIN   = "https://identity.${data.terraform_remote_state.azure.outputs.domain}"
        })
      }
    })
  ]
}