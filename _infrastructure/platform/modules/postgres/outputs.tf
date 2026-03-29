output "host" {
  value = "${helm_release.postgres.name}.${helm_release.postgres.namespace}.svc.cluster.local"
}

output "port" {
  value = var.port
}

output "database" {
  value = var.database
}