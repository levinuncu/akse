data "terraform_remote_state" "azure" {
  backend = "local"
  config = {
    path = "../azure/terraform.tfstate"
  }
}

locals {
  secrets = {
    rabbitmq = {
      name = "rabbitmq-secret"
      keys = {
        password = {
          secret_key = "password"
          remote_key = data.terraform_remote_state.azure.outputs.secret_keys.rabbitmq.password
        }
        username = {
          secret_key = "username"
          remote_key = data.terraform_remote_state.azure.outputs.secret_keys.rabbitmq.username
        }
        cookie = {
          secret_key = "cookie"
          remote_key = data.terraform_remote_state.azure.outputs.secret_keys.rabbitmq.cookie
        }
      }
    }
    postgres = {
      name = "postgres-secret"
      keys = {
        password = {
          secret_key = "password"
          remote_key = data.terraform_remote_state.azure.outputs.secret_keys.postgres.password
        }
        username = {
          secret_key = "username"
          remote_key = data.terraform_remote_state.azure.outputs.secret_keys.postgres.username
        }
      }
    }
    keycloak = {
      name = "keycloak-secret"
      keys = {
        password = {
          secret_key = "password"
          remote_key = data.terraform_remote_state.azure.outputs.secret_keys.keycloak.password
        }
        secret = {
          secret_key = "secret"
          remote_key = data.terraform_remote_state.azure.outputs.secret_keys.keycloak.secret
        }
      }
    }
    tls_certificate = {
      name = "pipgroup-tls-secret"
      keys = {
        certificate = {
          secret_key = "pfx"
          remote_key = data.terraform_remote_state.azure.outputs.secret_keys.tls_certificate
        }
      }
    }
  }
  domain        = "pipgroup.de"
  keycloak_host = "auth.${local.domain}"
  identity_host = "identity.${local.domain}"
}

module "aks" {
  source   = "./modules/aks"
  name     = "aks-akse"
  location = data.terraform_remote_state.azure.outputs.location
  resource_group = {
    name = data.terraform_remote_state.azure.outputs.resource_group_name
  }
  container_registry = {
    id = data.terraform_remote_state.azure.outputs.container_registry_id
  }
  log_analytics_workspace = {
    id = data.terraform_remote_state.azure.outputs.log_analytics_workspace_id
  }
}

module "secrets" {
  source   = "./modules/secrets"
  location = data.terraform_remote_state.azure.outputs.location
  resource_group = {
    name = data.terraform_remote_state.azure.outputs.resource_group_name
  }
  key_vault = {
    id        = data.terraform_remote_state.azure.outputs.key_vault_id
    vault_uri = data.terraform_remote_state.azure.outputs.key_vault_vault_uri
  }
  aks = {
    oidc_issuer_url = module.aks.oidc_issuer_url
  }
  secrets = [
    {
      name       = local.secrets.postgres.name
      namespaces = ["postgres", "keycloak", "backends"]
      data       = [local.secrets.postgres.keys.username, local.secrets.postgres.keys.password]
    },
    {
      name       = local.secrets.rabbitmq.name
      namespaces = ["rabbitmq", "backends"]
      data       = [local.secrets.rabbitmq.keys.username, local.secrets.rabbitmq.keys.password, local.secrets.rabbitmq.keys.cookie]
    },
    {
      name       = local.secrets.keycloak.name
      namespaces = ["keycloak", "backends"]
      data       = [local.secrets.keycloak.keys.password, local.secrets.keycloak.keys.secret]
    },
    {
      name        = local.secrets.tls_certificate.name
      namespaces  = ["keycloak", "frontend", "backends"]
      target_type = "kubernetes.io/tls"
      target_data = {
        "tls.crt" = "{{ .pfx | b64dec | pkcs12cert }}"
        "tls.key" = "{{ .pfx | b64dec | pkcs12key }}"
      }
      data = [local.secrets.tls_certificate.keys.certificate]
    },
  ]
}

module "rabbitmq" {
  source    = "./modules/rabbitmq"
  name      = "rabbitmq"
  namespace = "rabbitmq"
  key_vault = {
    id = data.terraform_remote_state.azure.outputs.key_vault_id
  }
  port        = 5672
  secret_name = local.secrets.rabbitmq.name
  secrets = {
    password = local.secrets.rabbitmq.keys.password
    cookie   = local.secrets.rabbitmq.keys.cookie
    username = local.secrets.rabbitmq.keys.username
  }
  depends_on = [module.secrets]
}

module "postgres" {
  source    = "./modules/postgres"
  name      = "postgres"
  namespace = "postgres"
  disk = {
    id   = data.terraform_remote_state.azure.outputs.postgres_disk_id
    size = data.terraform_remote_state.azure.outputs.postgres_disk_size
  }
  aks = {
    principal_id = module.aks.principal_id
  }
  key_vault = {
    id = data.terraform_remote_state.azure.outputs.key_vault_id
  }
  port        = 5432
  database    = "akse"
  secret_name = local.secrets.postgres.name
  secrets = {
    password = local.secrets.postgres.keys.password
    username = local.secrets.postgres.keys.username
  }
  depends_on = [module.secrets]
}

module "ingress" {
  source    = "./modules/ingress"
  name      = "ingress"
  namespace = "ingress"
  resource_group = {
    name = data.terraform_remote_state.azure.outputs.resource_group_name
  }
  public_ip = {
    id   = data.terraform_remote_state.azure.outputs.public_ip_id
    name = data.terraform_remote_state.azure.outputs.public_ip_name
  }
  aks = {
    principal_id = module.aks.principal_id
  }
}

module "keycloak" {
  source       = "./modules/keycloak"
  name         = "keycloak"
  namespace    = "keycloak"
  realm        = "akse"
  client_id    = "akse-client-id"
  redirect_uri = "https://${local.identity_host}/service/identity/v1/api/auth/callback"
  web_origin   = "https://${local.identity_host}"
  key_vault = {
    id = data.terraform_remote_state.azure.outputs.key_vault_id
  }
  ingress = {
    host = local.keycloak_host
    path = "/"
  }
  postgres = {
    host     = module.postgres.host
    port     = module.postgres.port
    database = module.postgres.database
  }
  tls_secret_name      = local.secrets.tls_certificate.name
  keycloak_secret_name = local.secrets.keycloak.name
  keycloak_secrets     = local.secrets.keycloak.keys
  postgres_secret_name = local.secrets.postgres.name
  postgres_secrets     = local.secrets.postgres.keys
  depends_on           = [module.secrets]
}

module "frontend" {
  source    = "./modules/service"
  name      = "frontend"
  namespace = "frontend"
  ingress_annotations = {
    "nginx.ingress.kubernetes.io/from-to-www-redirect" = "true"
  }
  image = {
    registry = data.terraform_remote_state.azure.outputs.container_registry_login_server
    name     = "frontend"
    tag      = "latest"
  }
  container = {
    port = 80
  }
  ingress = {
    host = local.domain
    path = "/"
  }
  tls_secret_name = local.secrets.tls_certificate.name
}

module "identity_backend" {
  source    = "./modules/service"
  name      = "identity-backend"
  namespace = "backends"
  image = {
    registry = data.terraform_remote_state.azure.outputs.container_registry_login_server
    name     = "identity-backend"
    tag      = "latest"
  }
  container = {
    port = 3000
    envs = [
      {
        name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        value = data.terraform_remote_state.azure.outputs.application_insights_connection_string
      },
      {
        name  = "POSTGRES_HOST"
        value = module.postgres.host
      },
      {
        name  = "POSTGRES_PORT"
        value = module.postgres.port
      },
      {
        name  = "POSTGRES_DB"
        value = module.postgres.database
      },
      {
        name = "POSTGRES_USER"
        value_from = {
          secret_name = local.secrets.postgres.name
          secret_key  = local.secrets.postgres.keys.username.secret_key
        }
      },
      {
        name = "POSTGRES_PASSWORD"
        value_from = {
          secret_name = local.secrets.postgres.name
          secret_key  = local.secrets.postgres.keys.password.secret_key
        }
      },
      {
        name  = "RABBITMQ_HOST"
        value = module.rabbitmq.host
      },
      {
        name  = "RABBITMQ_PORT"
        value = module.rabbitmq.port
      },
      {
        name = "RABBITMQ_USER"
        value_from = {
          secret_name = local.secrets.rabbitmq.name
          secret_key  = local.secrets.rabbitmq.keys.username.secret_key
        }
      },
      {
        name = "RABBITMQ_PASSWORD"
        value_from = {
          secret_name = local.secrets.rabbitmq.name
          secret_key  = local.secrets.rabbitmq.keys.password.secret_key
        }
      },
      {
        name  = "KEYCLOAK_URL"
        value = "https://${module.keycloak.ingress_host}"
      },
      {
        name  = "KEYCLOAK_REALM"
        value = module.keycloak.realm
      },
      {
        name  = "KEYCLOAK_CLIENT_ID"
        value = module.keycloak.client_id
      },
      {
        name = "KEYCLOAK_SECRET"
        value_from = {
          secret_name = local.secrets.keycloak.name
          secret_key  = local.secrets.keycloak.keys.secret.secret_key
        }
      },
    ]
  }
  ingress = {
    host = local.identity_host
    path = "/"
  }
  tls_secret_name = local.secrets.tls_certificate.name
  depends_on      = [module.secrets]
}
