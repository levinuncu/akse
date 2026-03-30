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
        name = kubernetes_service_account.eso_akv_sa.metadata[0].name
      }
    })
  ]
  depends_on = [module.aks, azurerm_role_assignment.kv_secrets]
}

resource "helm_release" "secret_store" {
  name                       = "secret-store"
  chart                      = "../helm/secret-store"
  disable_openapi_validation = true
  values = [
    yamlencode({
      vaultUrl           = module.kv.vault_uri
      serviceAccountName = kubernetes_service_account.eso_akv_sa.metadata[0].name
    })
  ]
  depends_on = [helm_release.external_secrets_operator, azurerm_role_assignment.kv_secrets]
}

resource "helm_release" "postgres_secret" {
  name                       = "postgres-secret"
  chart                      = "../helm/external-secret"
  disable_openapi_validation = true
  values = [
    yamlencode({
      name            = "postgres-secret"
      secretStoreName = helm_release.secret_store.name
      data = [
        { secretKey = "password", remoteRef = { key = "postgres-password" } },
      ]
    })
  ]
  depends_on = [helm_release.external_secrets_operator, azurerm_role_assignment.kv_secrets]
}

resource "helm_release" "rabbitmq_secret" {
  name                       = "rabbitmq-secret"
  chart                      = "../helm/external-secret"
  disable_openapi_validation = true
  values = [
    yamlencode({
      name            = "rabbitmq-secret"
      secretStoreName = helm_release.secret_store.name
      data = [
        { secretKey = "password", remoteRef = { key = "rabbitmq-password" } },
        { secretKey = "cookie", remoteRef = { key = "rabbitmq-cookie" } }
      ]
    })
  ]
  depends_on = [helm_release.external_secrets_operator, azurerm_role_assignment.kv_secrets]
}

resource "helm_release" "rabbitmq" {
  name    = "rabbitmq"
  chart   = "oci://registry-1.docker.io/cloudpirates/rabbitmq"
  version = "0.19.6"
  values = [
    yamlencode({
      service = {
        amqpPort = var.rabbitmq_port
      }
      auth = {
        username                = var.rabbitmq_user
        existingSecret          = helm_release.rabbitmq_secret.name
        existingPasswordKey     = "password"
        existingErlangCookieKey = "cookie"
      }
    })
  ]
  depends_on = [helm_release.rabbitmq_secret]
}

// TODO: Deploy postgres not with kubernetes but directly as azure service?
// TODO: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server
resource "helm_release" "postgres" {
  name    = "postgres"
  chart   = "oci://registry-1.docker.io/cloudpirates/postgres"
  version = "0.18.3"
  values = [
    yamlencode({
      service = {
        port       = var.postgres_port
        targetPort = var.postgres_port
      }
      auth = {
        username         = var.postgres_user
        database         = var.postgres_database
        existingSecret   = helm_release.postgres_secret.name
        secretKeys = {
          adminPasswordKey = "password"
        }
      }
    })
  ]
  depends_on = [helm_release.postgres_secret]
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.12.2"
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

resource "helm_release" "backend" {
  name  = "backend"
  chart = "../helm/backend-service"
  values = [
    yamlencode({
      name = "backend"
      image = {
        repository = "${module.acr.login_server}/backend"
        tag        = "latest"
      }
      containerPort = 80
      targetPort    = 80
      path          = "/backend"
      envs = [
        {
          name  = "POSTGRES_HOST"
          value = "${helm_release.postgres.name}.${helm_release.postgres.namespace}.svc.cluster.local"
        },
        {
          name  = "POSTGRES_PORT"
          value = var.postgres_port
        },
        {
          name  = "POSTGRES_USER"
          value = var.postgres_user
        },
        {
          name  = "POSTGRES_DATABASE"
          value = var.postgres_database
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
          value = var.rabbitmq_port
        },
        {
          name  = "RABBITMQ_USER"
          value = var.rabbitmq_user
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
      ]
    })
  ]
  depends_on = [helm_release.postgres, helm_release.rabbitmq]
}