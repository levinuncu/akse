variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "disk" {
  type = object({
    id   = string
    size = string
  })
}

variable "aks" {
  type = object({
    principal_id = string
  })
}

variable "key_vault" {
  type = object({
    id = string
  })
}

variable "port" {
  type = number
}

variable "database" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "secrets" {
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

