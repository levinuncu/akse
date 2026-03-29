data "azurerm_client_config" "current" {}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "random_password" "certificate" {
  length  = 24
  special = true
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.registration.account_key_pem
  common_name               = var.dns_zone.name
  subject_alternative_names = ["*.${var.dns_zone.name}"]
  certificate_p12_password  = random_password.certificate.result
  dns_challenge {
    provider = "azuredns"
    config = {
      AZURE_RESOURCE_GROUP = var.resource_group.name
      AZURE_ZONE_NAME      = var.dns_zone.name
      AZURE_TTL            = 300
    }
  }
}

resource "azurerm_key_vault_certificate" "certificate" {
  name         = var.certificate_secret
  key_vault_id = var.key_vault.id
  certificate {
    contents = acme_certificate.certificate.certificate_p12
    password = acme_certificate.certificate.certificate_p12_password
  }
  depends_on = [azurerm_role_assignment.kv_certificates]
}

resource "azurerm_role_assignment" "kv_certificates" {
  scope                = var.key_vault.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}