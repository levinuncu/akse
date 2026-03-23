variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "kv_name" {
  type = string
}

variable "acr_name" {
  type = string
}

variable "aks_name" {
  type = string
}

variable "postgres_user" {
  type    = string
  default = "postgres"
}

variable "postgres_database" {
  type = string
}

variable "postgres_port" {
  type    = number
  default = 5432
}

variable "rabbitmq_user" {
  type    = string
  default = "rabbitmq"
}

variable "rabbitmq_port" {
  type    = number
  default = 5672
}