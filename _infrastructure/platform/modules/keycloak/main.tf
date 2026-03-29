data "azurerm_key_vault_secret" "secret" {
  name         = var.keycloak_secrets.secret.remote_key
  key_vault_id = var.key_vault.id
}

resource "helm_release" "keycloak" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  chart            = "oci://registry-1.docker.io/cloudpirates/keycloak"
  version          = "0.19.7"
  timeout          = 1800
  values = [
    yamlencode({
      ingress = {
        enabled   = true
        className = "nginx"
        annotations = {
          "nginx.ingress.kubernetes.io/rewrite-target" = "/"
        }
        hosts = [
          {
            host = var.ingress.host
            paths = [
              {
                path     = var.ingress.path
                pathType = "Prefix"
              }
            ]
          }
        ]
        tls = [
          {
            secretName = var.tls_secret_name
            hosts      = [var.ingress.host]
          }
        ]
      }
      keycloak = {
        proxyHeaders   = "xforwarded"
        hostname       = "https://${var.ingress.host}"
        existingSecret = var.keycloak_secret_name
        secretKeys = {
          adminPasswordKey = var.keycloak_secrets.password.secret_key
        }
      }
      postgres = {
        enabled = false
      }
      database = {
        type           = "postgres"
        host           = var.postgres.host
        port           = tostring(var.postgres.port)
        name           = var.postgres.database
        existingSecret = var.postgres_secret_name
        secretKeys = {
          passwordKey = var.postgres_secrets.password.secret_key
          usernameKey = var.postgres_secrets.username.secret_key
        }
      }
      realm = {
        import = true
        configFile = templatefile("./../../keycloak/prod-realm.json.tpl", {
          REALM        = var.realm
          CLIENT_ID    = var.client_id
          SECRET       = data.azurerm_key_vault_secret.secret.value
          REDIRECT_URI = var.redirect_uri
          WEB_ORIGIN   = var.web_origin
        })
      }
    })
  ]
}