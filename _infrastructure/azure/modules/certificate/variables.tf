variable "email" {
  type = string
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "dns_zone" {
  type = object({
    name = string
  })
}

variable "certificate_secret" {
  type = string
}

variable "key_vault" {
  type = object({
    id = string
  })
}
