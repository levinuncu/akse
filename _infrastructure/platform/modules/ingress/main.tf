resource "azurerm_role_assignment" "network_contributor" {
  scope                = var.public_ip.id
  role_definition_name = "Network Contributor"
  principal_id         = var.aks.principal_id
}

resource "helm_release" "ingress_nginx" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
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
    value = var.public_ip.name
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = var.resource_group.name
  }
  depends_on = [azurerm_role_assignment.network_contributor]
}