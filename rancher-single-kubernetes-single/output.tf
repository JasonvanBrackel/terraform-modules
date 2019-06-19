output "rancher_server" {
  value = "Rancher Server: ${azurerm_public_ip.rancher_publicip.ip_address}"
}

output "kubernetes_server" {
  value = "Kubernetes Server: ${azurerm_public_ip.kubernetes_publicip.ip_address}"
}

output "rancher_node_command" {
  value = "Add Nodes to K8s Cluster '${rancher2_cluster.manager.cluster_registration_token.0.node_command} <roles>'"
}


