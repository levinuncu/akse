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
}