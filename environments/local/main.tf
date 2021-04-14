module "cluster" {
  source              = "../../modules/kind"
  name                = "kind"
  control_plane_nodes = 1
  worker_nodes        = 1
}
