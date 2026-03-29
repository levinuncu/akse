variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "port" {
  type = number
}

variable "key_vault" {
  type = object({
    id = string
  })
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
    cookie = object({
      secret_key = string
      remote_key = string
    })
  })
}
