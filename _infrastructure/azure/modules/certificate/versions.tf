terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
    acme    = { source = "vancluever/acme", version = "~> 2.0" }
    random  = { source = "hashicorp/random", version = "~> 3.0" }
    tls     = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}