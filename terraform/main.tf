resource "kubernetes_namespace" "apps" {
  metadata {
    name = "bansikah-apps"
  }
}

# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend-deployment"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "frontend"
      }
    }
    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }
      spec {
        container {
          name  = "frontend-container"
          image = "bansikah/react-frontend:1.1.0"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Backend Deployment
resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend-deployment"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "backend"
        }
      }
      spec {
        container {
          name  = "backend-container"
          image = "bansikah/express-backend:1.1.0"
          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

# Frontend Service
resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend-service"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    selector = {
      app = "frontend"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

# Backend Service
resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend-service"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    selector = {
      app = "backend"
    }
    port {
      port        = 5000
      target_port = 5000
    }
    type = "ClusterIP"
  }
}

# Ingress Configuration
resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "bansikah-ingress"
    namespace = kubernetes_namespace.apps.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "express-react.bansikah.com"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
        path {
          path      = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.backend.metadata[0].name
              port {
                number = 5000
              }
            }
          }
        }
      }
    }
  }
}
