output "etcd-nodes" {
  value = "${azurerm_public_ip.etcd_publicip.*.ip_address}"
}

output "controlplane-nodes" {
  value = "${azurerm_public_ip.controlplane_publicip.*.ip_address}"
}


output "worker-nodes" {
  value = "${azurerm_public_ip.worker_publicip.*.ip_address}"
}

output "admin" {
    value = "${var.administrator_username}"
}

output "ssh" {
    value = "${var.administrator_ssh}"
}

output "subscription_id" {
    value = "${lookup(var.azure_authorization_terraform, "subscription_id")}"
}

output "tenant_id" {
    value = "${lookup(var.azure_authorization_terraform, "tenant_id")}"
}

output "client_id" {
    value = "${lookup(var.azure_authorization_terraform, "client_id")}"
}

output "client_secret" {
    value = "${lookup(var.azure_authorization_terraform, "client_secret")}"
}

output "region" {
    value = "${azurerm_resource_group.resourcegroup.location}"
}

output "subnet" {
    value = "${azurerm_subnet.subnet.name}"
}

output "vnet" {
    value = "${azurerm_virtual_network.network.name}"
}