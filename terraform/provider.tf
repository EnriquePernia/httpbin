terraform {
  required_providers {
    k3d = {
      source = "nikhilsbhat/k3d"
      version = "0.0.2"
    }
  }
}

// Configure GoCD Provider
provider "k3d" {
    // if no image is passed while creating cluster attribute `kubernetes_version` and `registry` would be used to construct an image name.
    kubernetes_version = "1.28.6-k3s1"
    k3d_api_version    = "k3d.io/v1alpha4"
    registry           = "rancher/k3s"
    kind               = "Simple"
    runtime            = "docker"
}