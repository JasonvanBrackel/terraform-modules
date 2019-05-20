output "node_command" {
  value = "${rancher2_cluster.manager.cluster_registration_token.0.node_command}"
}

output "windows_node_command" {
  value = "${rancher2_cluster.manager.cluster_registration_token.0.windows_node_command}"
}

