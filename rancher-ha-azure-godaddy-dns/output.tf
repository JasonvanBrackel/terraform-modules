# Supporting Software
output "rke_version" {
  value = "${var.rke_version}"
}

output "helm_version" {
  value = "${var.helm_version}"
}

output "docker_version" {
  value = "${var.docker_version}"
}

# Azure Location
output "resource_group" {
  value = "${var.azure_resource_group}"
}

# Node Public IPs, Private IPs, Hostnames
output "etcd_nodes" {
  value = "${azurerm_public_ip.etcd_publicip.*.ip_address}"
}

output "etcd_node_names" {
  value = "${azurerm_virtual_machine.etcd-machine.*.name}"
}

output "etcd_node_privateips" {
  value = "${azurerm_network_interface.etcd_nic.*.private_ip_address}"
}

output "controlplane_nodes" {
  value = "${azurerm_public_ip.controlplane_publicip.*.ip_address}"
}

output "controlplane_node_names" {
  value = "${azurerm_virtual_machine.controlplane-machine.*.name}"
}

output "controlplane_node_privateips" {
  value = "${azurerm_network_interface.controlplane_nic.*.private_ip_address}"
}

output "worker_nodes" {
  value = "${azurerm_public_ip.worker_publicip.*.ip_address}"
}

output "worker_node_names" {
  value = "${azurerm_virtual_machine.worker-machine.*.name}"
}

output "worker_node_privateips" {
  value = "${azurerm_network_interface.worker_nic.*.private_ip_address}"
}

# Credentials

output "admin" {
  value = "${var.administrator_username}"
}

output "ssh" {
  value = "${var.administrator_ssh}"
}

output "administrator_ssh_private" {
  value = "${var.administrator_ssh_private}"
}

# Rancher

output "rancher_hostname" {
  value = "${var.rancher_hostname}"
}

output "trafficmanager_fqdn" {
  value = "${azurerm_traffic_manager_profile.rke_traffic_manager_profile.fqdn}"
}