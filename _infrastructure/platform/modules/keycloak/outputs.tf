output "realm" {
  value = var.realm
}

output "client_id" {
  value = var.client_id
}

output "ingress_host" {
  value = "${var.ingress.host}${var.ingress.path}"
}