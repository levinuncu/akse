resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.15.1"
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/port_80_health-probe_protocol"
    value = "Tcp"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/port_443_health-probe_protocol"
    value = "Tcp"
  }
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-pip-name"
    value = data.terraform_remote_state.azure.outputs.pip_name
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = data.terraform_remote_state.azure.outputs.rg_name
  }
  depends_on = [azurerm_role_assignment.aks_network_contributor]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "1.20.0"
  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "cert_issuer" {
  name  = "cert-issuer"
  chart = "../helm/cert-issuer"
  values = [
    yamlencode({
      name          = "cert-issuer",
      tlsSecretName = local.tls_secret_name
    })
  ]
  depends_on = [helm_release.cert_manager]
}
