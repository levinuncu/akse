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

variable "container_registry" {
  type = object({
    id = string
  })
}

variable "log_analytics_workspace" {
  type = object({
    id = string
  })
}
