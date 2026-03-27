resource "helm_release" "identity_backend" {
  name  = "identity-backend"
  chart = "../helm/docker-image"
  values = [
    yamlencode({
      name = "identity-backend"
      image = {
        repository = "${data.terraform_remote_state.azure.outputs.acr_login_server}/identity-backend"
        tag        = "latest"
      }
      host           = "identity.${data.terraform_remote_state.azure.outputs.domain}"
      containerPort  = 3000
      path           = "/"
      tlsSecretName  = local.tls_secret_name
      certIssuerName = helm_release.cert_issuer.name,
      envs = [
        {
          name  = "APP_BASE_URL"
          value = "https://identity.${data.terraform_remote_state.azure.outputs.domain}"
        },

        {
          name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
          value = data.terraform_remote_state.azure.outputs.ai_connection_string
        },

        {
          name  = "POSTGRES_HOST"
          value = "${helm_release.postgres.name}.${helm_release.postgres.namespace}.svc.cluster.local"
        },
        {
          name  = "POSTGRES_PORT"
          value = local.postgres_port
        },
        {
          name = "POSTGRES_USER"
          valueFrom = {
            secretKeyRef = {
              name = helm_release.postgres_secret.name
              key  = "username"
            }
          }
        },
        {
          name  = "POSTGRES_DB"
          value = local.postgres_database
        },
        {
          name = "POSTGRES_PASSWORD"
          valueFrom = {
            secretKeyRef = {
              name = helm_release.postgres_secret.name
              key  = "password"
            }
          }
        },

        {
          name  = "RABBITMQ_HOST"
          value = "${helm_release.rabbitmq.name}.${helm_release.rabbitmq.namespace}.svc.cluster.local"
        },
        {
          name  = "RABBITMQ_PORT"
          value = local.rabbitmq_port
        },
        {
          name  = "RABBITMQ_USER"
          value = local.rabbitmq_user
        },
        {
          name = "RABBITMQ_PASSWORD"
          valueFrom = {
            secretKeyRef = {
              name = helm_release.rabbitmq_secret.name
              key  = "password"
            }
          }
        },

        {
          name  = "KEYCLOAK_URL"
          value = "https://${local.keycloak_host}"
        },
        {
          name  = "KEYCLOAK_REALM"
          value = local.keycloak_realm
        },
        {
          name  = "KEYCLOAK_CLIENT_ID"
          value = local.keycloak_client_id
        },
        {
          name = "KEYCLOAK_SECRET"
          valueFrom = {
            secretKeyRef = {
              name = helm_release.keycloak_secret.name
              key  = "secret"
            }
          }
        },
      ]
    })
  ]
  depends_on = [helm_release.ingress_nginx, azurerm_role_assignment.aks_acr_pull]
}

resource "helm_release" "frontend" {
  name  = "frontend"
  chart = "../helm/docker-image"
  values = [
    yamlencode({
      name = "frontend"
      image = {
        repository = "${data.terraform_remote_state.azure.outputs.acr_login_server}/frontend"
        tag        = "latest"
      }
      host           = data.terraform_remote_state.azure.outputs.domain
      containerPort  = 80
      path           = "/"
      tlsSecretName  = local.tls_secret_name
      certIssuerName = helm_release.cert_issuer.name,
    })
  ]
  depends_on = [helm_release.ingress_nginx, azurerm_role_assignment.aks_acr_pull]
}
