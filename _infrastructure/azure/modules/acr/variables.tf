variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group" {
  type = object({
    name = string
  })
}