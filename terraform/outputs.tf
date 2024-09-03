
output "opa_namespace" {
  description = "OPA Namespace"
  value       = kubernetes_namespace.opa.metadata[0].name
}

output "opa_service_name" {
  description = "OPA Service Name"
  value       = kubernetes_service.opa.metadata[0].name
}

output "opa_webhook_name" {
  description = "OPA Validating Webhook Name"
  value       = kubernetes_validating_webhook_configuration.opa_webhook.metadata[0].name
}
