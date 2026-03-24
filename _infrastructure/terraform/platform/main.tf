locals {
  aks_name          = "aks-akse"
  postgres_user     = "postgres"
  postgres_database = "db-akse"
  postgres_port     = 5432
  rabbitmq_user     = "rabbitmq"
  rabbitmq_port     = 5672
}

data "terraform_remote_state" "azure" {
  backend = "local"
  config = {
    path = "../azure/terraform.tfstate"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = local.aks_name
  location                  = data.terraform_remote_state.azure.outputs.location
  resource_group_name       = data.terraform_remote_state.azure.outputs.rg_name
  dns_prefix                = "${local.aks_name}-dns"
  sku_tier                  = "Standard"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_A2_v2"
  }
  identity {
    type = "SystemAssigned"
  }
}