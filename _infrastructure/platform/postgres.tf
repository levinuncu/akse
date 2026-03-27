resource "helm_release" "postgres_volume" {
  name  = "postgres-volume"
  chart = "../helm/persistent-volume"
  values = [
    yamlencode({
      name = "postgres-volume"
      disk = {
        name         = data.terraform_remote_state.azure.outputs.pg_disk_name
        volumeHandle = data.terraform_remote_state.azure.outputs.pg_disk_id
        size         = data.terraform_remote_state.azure.outputs.pg_disk_size
        fsType       = "ext4"
      }
    })
  ]
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "helm_release" "postgres_volume_claim" {
  name  = "postgres-volume-claim"
  chart = "../helm/persistent-volume-claim"
  values = [
    yamlencode({
      name = "postgres-volume-claim"
      disk = {
        size = data.terraform_remote_state.azure.outputs.pg_disk_size
      }
      volume = {
        name = helm_release.postgres_volume.name
      }
    })
  ]
}

resource "azurerm_key_vault_secret" "postgres_username" {
  name         = "postgres-username"
  key_vault_id = data.terraform_remote_state.azure.outputs.kv_id
  value        = local.postgres_user
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
        { secretKey = "username", remoteRef = { key = "postgres-username" } },
      ]
    })
  ]
  depends_on = [azurerm_key_vault_secret.postgres_username, helm_release.external_secrets_operator, azurerm_role_assignment.kv_secrets]
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
      persistence = {
        existingClaim = helm_release.postgres_volume_claim.name
      }
    })
  ]
  depends_on = [azurerm_role_assignment.aks_pg_disk_contributor]
}