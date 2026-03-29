data "azurerm_key_vault_secret" "username" {
  name         = var.secrets.username.remote_key
  key_vault_id = var.key_vault.id
}

resource "azurerm_role_assignment" "disk_contributor" {
  scope                = var.disk.id
  role_definition_name = "Contributor"
  principal_id         = var.aks.principal_id
}

resource "helm_release" "volume" {
  name             = "${var.name}-volume"
  namespace        = var.namespace
  create_namespace = true
  chart            = "./helm/persistent-volume"
  values = [
    yamlencode({
      capacityStorage = var.disk.size
      volumeHandle    = var.disk.id
    })
  ]
  depends_on = [azurerm_role_assignment.disk_contributor]
}

resource "helm_release" "volume_claim" {
  name             = "${var.name}-volume-claim"
  namespace        = var.namespace
  create_namespace = true
  chart            = "./helm/persistent-volume-claim"
  values = [
    yamlencode({
      requestsStorage = var.disk.size
      volumeName      = helm_release.volume.name
    })
  ]
}

resource "helm_release" "postgres" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  chart            = "oci://registry-1.docker.io/cloudpirates/postgres"
  version          = "0.18.3"
  values = [
    yamlencode({
      service = {
        port       = var.port
        targetPort = var.port
      }
      auth = {
        username       = data.azurerm_key_vault_secret.username.value
        database       = var.database
        existingSecret = var.secret_name
        secretKeys = {
          adminPasswordKey = var.secrets.password.secret_key
        }
      }
      persistence = {
        existingClaim = helm_release.volume_claim.name
      }
    })
  ]
}