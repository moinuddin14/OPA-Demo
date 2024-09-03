# Provider block to configure the Kubernetes provider
# This allows Terraform to interact with your Kubernetes cluster.
provider "kubernetes" {
  config_path = "~/.kube/config"  # Path to the kubeconfig file, which provides access to the cluster
}

# Resource block to create a namespace in Kubernetes
# Namespaces provide a scope for names and isolate resources within the cluster.
resource "kubernetes_namespace" "opa" {
  metadata {
    name = "opa-namespace"  # The name of the namespace to be created
  }
}

# Resource block to create a ConfigMap in Kubernetes
# A ConfigMap is used to store configuration data as key-value pairs.
resource "kubernetes_config_map" "opa_policy" {
  metadata {
    name      = "opa-configmap"                # Name of the ConfigMap
    namespace = kubernetes_namespace.opa.metadata[0].name  # Namespace in which the ConfigMap will be created
  }

  # Data block to define the policy in Rego syntax
  data = {
    "policy.rego" = <<-EOT
    package kubernetes.admission

    deny[{"msg": msg}] {
      input.request.kind.kind == "Pod"
      input.request.operation == "CREATE"
      input.request.object.spec.containers[_].resources.requests.cpu
      not input.request.object.spec.containers[_].resources.limits.cpu
      msg = "Container must have CPU limit"
    }
    EOT
  }
}

# Resource block to create a Deployment in Kubernetes
# A Deployment manages a set of identical pods, ensuring the desired number of pods are running.
resource "kubernetes_deployment" "opa" {
  metadata {
    name      = "opa-deployment"               # Name of the Deployment
    namespace = kubernetes_namespace.opa.metadata[0].name  # Namespace in which the Deployment will be created
  }

  spec {
    replicas = var.opa_replica_count  # Number of replicas (pods) to run for this deployment

    selector {
      match_labels = {
        app = "opa"  # Label selector to identify the pods managed by this deployment
      }
    }

    template {
      metadata {
        labels = {
          app = "opa"  # Label to be applied to the pods created by this deployment
        }
      }

      spec {
        container {
          name  = "opa"                                # Name of the container
          image = "${var.opa_image}:${var.opa_image_tag}"  # Docker image for the container

          resources {
            limits {
              cpu    = var.opa_cpu_limit    # CPU limit for the container
              memory = var.opa_memory_limit  # Memory limit for the container
            }

            requests {
              cpu    = var.opa_cpu_request    # CPU request for the container
              memory = var.opa_memory_request  # Memory request for the container
            }
          }

          volume_mount {
            name       = "policy"    # Name of the volume to mount
            mount_path = "/policy"   # Path inside the container where the volume will be mounted
          }
        }

        volume {
          name = "policy"  # Name of the volume

          config_map {
            name = kubernetes_config_map.opa_policy.metadata[0].name  # ConfigMap to be used as the source for this volume
          }
        }
      }
    }
  }
}

# Resource block to create a Service in Kubernetes
# A Service provides a stable network endpoint for a set of pods.
resource "kubernetes_service" "opa" {
  metadata {
    name      = "opa-service"                # Name of the Service
    namespace = kubernetes_namespace.opa.metadata[0].name  # Namespace in which the Service will be created
  }

  spec {
    type = var.opa_service_type  # Type of the Service (e.g., ClusterIP, NodePort, LoadBalancer)

    selector = {
      app = "opa"  # Label selector to identify the pods that the Service should route traffic to
    }

    port {
      port        = var.opa_service_port  # Port on which the Service will be exposed
      target_port = 443                   # Port on the pod that the Service should forward traffic to
    }
  }
}

# Resource block to create a ValidatingWebhookConfiguration in Kubernetes
# A ValidatingWebhookConfiguration registers a webhook that intercepts admission requests to the API server.
resource "kubernetes_validating_webhook_configuration" "opa_webhook" {
  metadata {
    name = "opa-webhook"  # Name of the ValidatingWebhookConfiguration
  }

  webhook {
    name = "kubernetes.opa.admission"  # Name of the webhook

    client_config {
      service {
        name      = kubernetes_service.opa.metadata[0].name  # Name of the Service that handles the webhook requests
        namespace = kubernetes_namespace.opa.metadata[0].name  # Namespace of the Service
        path      = "/v1/admit"  # Path on the Service where the webhook requests will be sent
      }
      ca_bundle = var.webhook_ca_bundle  # CA bundle to validate the TLS certificate of the webhook's service
    }

    rules {
      api_groups   = [""]        # API groups to which this webhook applies ("" for core API group)
      api_versions = ["v1"]      # API versions to which this webhook applies
      operations   = ["CREATE"]  # Operations to which this webhook applies (e.g., CREATE, UPDATE, DELETE)
      resources    = ["pods"]    # Resources to which this webhook applies
    }

    admission_review_versions = ["v1"]  # Versions of AdmissionReview that the webhook expects
    side_effects              = "None"  # Whether the webhook has side effects (None, Some, Unknown)
  }
}

# Resource block to create a Pod in Kubernetes
# This pod is compliant with the OPA policy, as it has CPU limits defined.
resource "kubernetes_pod" "compliant_pod" {
  metadata {
    name      = "compliant-pod"              # Name of the Pod
    namespace = kubernetes_namespace.opa.metadata[0].name  # Namespace in which the Pod will be created
  }

  spec {
    container {
      name  = "nginx"  # Name of the container
      image = "nginx"  # Docker image for the container

      resources {
        limits {
          cpu = "100m"  # CPU limit for the container, making it compliant with the OPA policy
        }
      }
    }
  }
}

# Resource block to create another Pod in Kubernetes
# This pod is non-compliant with the OPA policy, as it has no CPU limits defined.
resource "kubernetes_pod" "test_pod" {
  metadata {
    name      = "test-pod"                  # Name of the Pod
    namespace = kubernetes_namespace.opa.metadata[0].name  # Namespace in which the Pod will be created
  }

  spec {
    container {
      name  = "nginx"  # Name of the container
      image = "nginx"  # Docker image for the container

      resources {
        requests {
          cpu = "100m"  # CPU request for the container, but no CPU limit is defined, making it non-compliant
        }
      }
    }
  }
}
