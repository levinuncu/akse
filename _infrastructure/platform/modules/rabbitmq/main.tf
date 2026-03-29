data "azurerm_key_vault_secret" "username" {
  name         = var.secrets.username.remote_key
  key_vault_id = var.key_vault.id
}

resource "helm_release" "rabbitmq" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  chart            = "oci://registry-1.docker.io/cloudpirates/rabbitmq"
  version          = "0.19.6"
  values = [
    yamlencode({
      service = {
        amqpPort = var.port
      }
      auth = {
        username                = data.azurerm_key_vault_secret.username.value
        existingSecret          = var.secret_name
        existingPasswordKey     = var.secrets.password.secret_key
        existingErlangCookieKey = var.secrets.cookie.secret_key
      }
    })
  ]
}