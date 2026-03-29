

resource "helm_release" "service" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  chart            = "./helm/docker-service"
  values = [
    yamlencode({
      ingress_annotations = var.ingress_annotations
      imageRegistry       = var.image.registry
      imageName           = var.image.name
      imageTag            = var.image.tag
      containerPort       = var.container.port
      host                = var.ingress.host
      path                = var.ingress.path
      tlsSecretName       = var.tls_secret_name
      envs = concat(
        [
          {
            name  = "APP_PORT"
            value = var.container.port
          },
          {
            name  = "APP_BASE_URL"
            value = "https://${var.ingress.host}${var.ingress.path}"
          }
        ],
        [
          for env in coalesce(var.container.envs, []) : {
            name  = env.name
            value = env.value
            valueFrom = env.value_from != null ? {
              secretKeyRef = {
                name = env.value_from.secret_name
                key  = env.value_from.secret_key
              }
            } : null
          }
        ]
      )
    })
  ]
}


