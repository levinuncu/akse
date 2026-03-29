variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "realm" {
  type = string
}

variable "client_id" {
  type = string
}

variable "redirect_uri" {
  type = string
}

variable "web_origin" {
  type = string
}

variable "key_vault" {
  type = object({
    id = string
  })
}

variable "ingress" {
  type = object({
    host = string
    path = string
  })
}

variable "postgres" {
  type = object({
    host     = string
    port     = number
    database = string
  })
}

variable "tls_secret_name" {
  type = string
}

variable "keycloak_secret_name" {
  type = string
}

variable "keycloak_secrets" {
  type = object({
    secret = object({
      secret_key = string
      remote_key = string
    })
    password = object({
      secret_key = string
      remote_key = string
    })
  })
}

variable "postgres_secret_name" {
  type = string
}

variable "postgres_secrets" {
  type = object({
    password = object({
      secret_key = string
      remote_key = string
    })
    username = object({
      secret_key = string
      remote_key = string
    })
  })
}