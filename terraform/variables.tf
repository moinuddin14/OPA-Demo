
variable "opa_replica_count" {
  description = "Number of replicas for the OPA deployment"
  type        = number
  default     = 1
}

variable "opa_image" {
  description = "OPA Docker image repository"
  type        = string
  default     = "openpolicyagent/opa"
}

variable "opa_image_tag" {
  description = "OPA Docker image tag"
  type        = string
  default     = "latest"
}

variable "opa_cpu_limit" {
  description = "CPU limit for the OPA container"
  type        = string
  default     = "100m"
}

variable "opa_memory_limit" {
  description = "Memory limit for the OPA container"
  type        = string
  default     = "128Mi"
}

variable "opa_cpu_request" {
  description = "CPU request for the OPA container"
  type        = string
  default     = "100m"
}

variable "opa_memory_request" {
  description = "Memory request for the OPA container"
  type        = string
  default     = "128Mi"
}

variable "opa_service_type" {
  description = "Service type for the OPA service"
  type        = string
  default     = "ClusterIP"
}

variable "opa_service_port" {
  description = "Port for the OPA service"
  type        = number
  default     = 443
}

variable "webhook_ca_bundle" {
  description = "CA Bundle for the Validating Webhook"
  type        = string
  default     = ""
}
