variable "name" {
  type = string
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "ip_address" {
  type = string
}