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
  chart                      = "../../helm/secret-store"
  disable_openapi_validation = true
  values = [
    yamlencode({
      vaultUrl           = data.terraform_remote_state.azure.outputs.kv_vault_uri
      serviceAccountName = kubernetes_service_account.eso_akv_sa.metadata[0].name
    })
  ]
  depends_on = [helm_release.external_secrets_operator, azurerm_role_assignment.kv_secrets]
}

resource "helm_release" "postgres_secret" {
  name                       = "postgres-secret"
  chart                      = "../../helm/external-secret"
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
  chart                      = "../../helm/external-secret"
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

// TODO: helm release for keycloak

resource "helm_release" "rabbitmq" {
  name    = "rabbitmq"
  chart   = "oci://registry-1.docker.io/cloudpirates/rabbitmq"
  version = "0.19.6"
  values = [
    yamlencode({
      service = {
        amqpPort = local.rabbitmq_port
      }
      auth = {
        username                = local.rabbitmq_user
        existingSecret          = helm_release.rabbitmq_secret.name
        existingPasswordKey     = "password"
        existingErlangCookieKey = "cookie"
      }
    })
  ]
  depends_on = [helm_release.rabbitmq_secret]
}

resource "helm_release" "postgres" {
  name    = "postgres"
  chart   = "oci://registry-1.docker.io/cloudpirates/postgres"
  version = "0.18.3"
  values = [
    yamlencode({
      service = {
        port       = local.postgres_port
        targetPort = local.postgres_port
      }
      auth = {
        username       = local.postgres_user
        database       = local.postgres_database
        existingSecret = helm_release.postgres_secret.name
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
  version          = "4.15.1"
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/port_80_health-probe_protocol"
    value = "Tcp"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/port_443_health-probe_protocol"
    value = "Tcp"
  }
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-pip-name"
    value = data.terraform_remote_state.azure.outputs.pip_name
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = data.terraform_remote_state.azure.outputs.rg_name
  }
  depends_on = [azurerm_role_assignment.aks_network_contributor]
}

resource "helm_release" "identity-backend" {
  name  = "identity-backend"
  chart = "../../helm/docker-image"
  values = [
    yamlencode({
      name = "identity-backend"
      image = {
        repository = "${data.terraform_remote_state.azure.outputs.acr_login_server}/identity-backend"
        tag        = "latest"
      }
      host          = "identity.${data.terraform_remote_state.azure.outputs.domain}"
      containerPort = 3000
      path          = "/"
      envs = [
        {
          name  = "POSTGRES_HOST"
          value = "${helm_release.postgres.name}.${helm_release.postgres.namespace}.svc.cluster.local"
        },
        {
          name  = "POSTGRES_PORT"
          value = local.postgres_port
        },
        {
          name  = "POSTGRES_USER"
          value = local.postgres_user
        },
        {
          name  = "POSTGRES_DATABASE"
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
      ]
    })
  ]
  depends_on = [helm_release.postgres, helm_release.ingress_nginx, azurerm_role_assignment.aks_acr_pull]
}

resource "helm_release" "frontend" {
  name  = "frontend"
  chart = "../../helm/docker-image"
  values = [
    yamlencode({
      name = "frontend"
      image = {
        repository = "${data.terraform_remote_state.azure.outputs.acr_login_server}/frontend"
        tag        = "latest"
      }
      host          = data.terraform_remote_state.azure.outputs.domain
      containerPort = 80
      path          = "/"
    })
  ]
  depends_on = [helm_release.ingress_nginx, azurerm_role_assignment.aks_acr_pull]
}