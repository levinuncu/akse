output "ingress_host" {
  value = "${var.ingress.host}${var.ingress.path}"
}