# https://kind.sigs.k8s.io/
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

# https://kind.sigs.k8s.io/docs/user/loadbalancer/
resource "null_resource" "install_metalb" {
  triggers = {
    trigger = kind_cluster.cluster.name
  }
  provisioner "local-exec" {
    command = <<-EOF
      kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
      kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
      kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
      while [[ $(kubectl -n metallb-system get pods -l app=metallb,component=controller -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for metallb" && sleep 1; done
      DOCKER_SUBNET=`docker network inspect -f '{{ (index .IPAM.Config 0).Subnet }}' ${var.name}`
      MIN_LB_ADDRESS=`echo 'cidrhost("'$DOCKER_SUBNET'", 200)' | terraform console -state=/tmp/tfstate | tr -d '"'`
      MAX_LB_ADDRESS=`echo 'cidrhost("'$DOCKER_SUBNET'", 250)' | terraform console -state=/tmp/tfstate | tr -d '"'`
      cat <<CONFIG_MAP_EOF | kubectl apply -f -
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: config
        namespace: metallb-system
      data:
        config: |
          address-pools:
          - name: default
            protocol: layer2
            addresses:
            - $MIN_LB_ADDRESS-$MAX_LB_ADDRESS
      CONFIG_MAP_EOF
    EOF
  }
  depends_on = [kind_cluster.cluster]
}
