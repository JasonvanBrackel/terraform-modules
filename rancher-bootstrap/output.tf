output "etcd_nodes" {
  value = "${azurerm_public_ip.etcd_publicip.*.ip_address}"
}

output "controlplane_nodes" {
  value = "${azurerm_public_ip.controlplane_publicip.*.ip_address}"
}

output "worker_nodes" {
  value = "${azurerm_public_ip.worker_publicip.*.ip_address}"
}

output "admin" {
  value = "${var.administrator_username}"
}

output "ssh" {
  value = "${var.administrator_ssh}"
}

output "administrator_ssh_private" {
  value = "${var.administrator_ssh_private}"
}

output "subscription_id" {
  value = "${var.azure_authorization_terraform["subscription_id"]}"
}

output "tenant_id" {
  value = "${var.azure_authorization_terraform["tenant_id"]}"
}

output "client_id" {
  value = "${var.azure_authorization_terraform["client_id"]}"
}

output "client_secret" {
  value = "${var.azure_authorization_terraform["client_secret"]}"
}

output "region" {
  value = "${azurerm_resource_group.resourcegroup.location}"
}

output "resourcegroup" {
  value = "${azurerm_resource_group.resourcegroup.name}"
}

output "subnet" {
  value = "${azurerm_subnet.subnet.name}"
}

output "vnet" {
  value = "${azurerm_virtual_network.network.name}"
}
