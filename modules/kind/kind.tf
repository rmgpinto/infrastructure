resource "kind_cluster" "cluster" {
  name = var.name
  kind_config {
    kind        = "Cluster"
    api_version = var.api_version
    dynamic "node" {
      for_each = range(var.control_plane_nodes)
      content {
        role = "control-plane"
      }
    }
    dynamic "node" {
      for_each = range(var.worker_nodes)
      content {
        role = "worker"
      }
    }
  }
  wait_for_ready = true
}
