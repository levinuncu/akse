output "host" {
  value = "${helm_release.rabbitmq.name}.${helm_release.rabbitmq.namespace}.svc.cluster.local"
}

output "port" {
  value = var.port
}