variable "location" {
  type = string
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "key_vault" {
  type = object({
    id        = string
    vault_uri = string
  })
}

variable "aks" {
  type = object({
    oidc_issuer_url = string
  })
}

variable "secrets" {
  type = list(object({
    name        = string
    namespaces  = set(string)
    target_type = optional(string)
    target_data = optional(map(string))
    data = set(object({
      secret_key = string
      remote_key = string
    }))
  }))
}