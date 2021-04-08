variable "name" {
  type        = string
  default     = "kind"
  description = "Kind cluster name"
}

variable "api_version" {
  type        = string
  default     = "kind.x-k8s.io/v1alpha4"
  description = "Kind api version"
}

variable "control_plane_nodes" {
  type        = number
  default     = 1
  description = "Number of control plane nodes"
}

variable "worker_nodes" {
  type        = number
  default     = 1
  description = "Number of worker plane nodes"
}
