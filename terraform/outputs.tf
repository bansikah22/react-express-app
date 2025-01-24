output "ingress_url" {
  value = "express-react.bansikah.com"
}

output "namespace" {
  value = kubernetes_namespace.apps.metadata[0].name
}
