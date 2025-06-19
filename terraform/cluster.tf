resource "k3d_cluster" "sample_cluster" {
    name          = "playson"
    servers_count = 1
    agents_count  = 2
    //  image = "rancher/k3s:v1.24.4-k3s1"
    kube_api {
        host_ip = "0.0.0.0"
        host_port = 6445
    }
    # Port mapping 
    ports {
        host_port      = 8080
        container_port = 80
        node_filters   = ["loadbalancer"]
    }

    k3d_options {
        no_loadbalancer = false
        no_image_volume = false
    }

    kube_config {
        update_default = true
        switch_context = true
    }
}

// Nodes creation based on variable
resource "k3d_node" "nodes" {
  for_each = var.nodes
  
  name     = "playson-${each.key}"
  cluster  = k3d_cluster.sample_cluster.name
  role     = each.value.role
  replicas = each.value.replicas
  memory   = each.value.memory
}