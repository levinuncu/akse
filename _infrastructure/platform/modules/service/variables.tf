variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "ingress_annotations" {
  type    = map(string)
  default = null
}

variable "image" {
  type = object({
    registry = string
    name     = string
    tag      = string
  })
}

variable "container" {
  type = object({
    port = number
    envs = optional(set(object({
      name  = string
      value = optional(string)
      value_from = optional(object({
        secret_name = string
        secret_key  = string
      }))
    })), [])
  })
  validation {
    condition = alltrue([
      for env in coalesce(var.container.envs, []) : (env.value != null) != (env.value_from != null)
    ])
    error_message = "Each container env must set exactly one of 'value' or 'value_from'."
  }
}

variable "ingress" {
  type = object({
    host = string
    path = string
  })
}

variable "tls_secret_name" {
  type = string
}
