terraform {
  required_version = "~> 1.3.2"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.14.0" #MARKER
    }
  }
}

provider "kubernetes" {
}

variable "namespace" {
  type    = string
  default = "kube-public"
}
variable "name" {
  type    = string
  default = "terraform-provider-kubernetes-issue-1877"
}

resource "kubernetes_secret" "self" {
  metadata {
    namespace = var.namespace
    name      = var.name
  }
}
