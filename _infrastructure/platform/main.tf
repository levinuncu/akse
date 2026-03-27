locals {
  aks_name           = "aks-akse"
  postgres_user      = "postgres"
  postgres_database  = "db-akse"
  postgres_port      = 5432
  rabbitmq_user      = "rabbitmq"
  rabbitmq_port      = 5672
  tls_secret_name    = "pipgroup-tls-secret"
  keycloak_host      = "auth.${data.terraform_remote_state.azure.outputs.domain}"
  keycloak_client_id = "akse-client-id"
  keycloak_realm     = "akse"
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
  network_profile {
    network_plugin = "azure"
  }
  oms_agent {
    log_analytics_workspace_id = data.terraform_remote_state.azure.outputs.law_id
  }
}