variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "aks" {
  type = object({
    principal_id = string
  })
}

variable "public_ip" {
  type = object({
    name = string
    id   = string
  })
}

variable "resource_group" {
  type = object({
    name = string
  })
}