################################## PROVIDERS
# Configure the Azure Provider
provider "azurerm" {
  subscription_id = "${lookup(var.azure_service_principal, "subscription_id")}"
  client_id       = "${lookup(var.azure_service_principal, "client_id")}"
  client_secret   = "${lookup(var.azure_service_principal, "client_secret")}"
  tenant_id       = "${lookup(var.azure_service_principal, "tenant_id")}"
  environment     = "${lookup(var.azure_service_principal, "environment")}"
}

# Configure the Rancher2 provider
provider "rancher2" {
  api_url    = "${var.rancher_api_url}"
  token_key  = "${var.rancher_api_token}"
  insecure = true
}

################################## Rancher
resource "rancher2_cluster" "manager" {
  name = "${var.rancher_cluster_name}"
  description = "Custom Rancher Cluster: ${var.rancher_cluster_name}"
  kind = "rke"
  rke_config {
    network {
      plugin = "canal"
    }
    cloud_provider {
      azure_cloud_provider {
        aad_client_id = "${lookup(var.azure_service_principal, "client_id")}"
        aad_client_secret = "${lookup(var.azure_service_principal, "client_secret")}"
        subscription_id = "${lookup(var.azure_service_principal, "subscription_id")}"
        tenant_id = "${lookup(var.azure_service_principal, "tenant_id")}"
      }
    }
  }
}

# Create a resource group
resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.azure_resource_group}"
  location = "${var.azure_region}"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "network" {
  name                = "${azurerm_resource_group.resourcegroup.name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${azurerm_resource_group.resourcegroup.name}-subnet"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  address_prefix       = "10.0.1.0/24"
}

################################ NSGs

# Create the network security group for the ranche node
resource "azurerm_network_security_group" "nsg_rancher" {
  name                = "${azurerm_resource_group.resourcegroup.name}-nsg-rancher"
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

  security_rule {
    name                       = "SSH"
    description                = "Inbound SSH Traffic"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Ingress-80"
    description                = "Inbound UI Traffic"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Ingress-443"
    description                = "Inbound Secure UI Traffic"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Egress-443"
    description                = "Outbound Rancher Catalog"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Egress-22"
    description                = "Outbound SSH for Docker Install on IaaS Clusters"
    priority                   = 1005
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Egress-2376"
    description                = "Outbound Docker Daemon TLS for IaaS Clusters"
    priority                   = 1006
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2376"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Create the network security group for the kubernetes node
resource "azurerm_network_security_group" "nsg_kubernetes" {
  name                = "${azurerm_resource_group.resourcegroup.name}-nsg-kubernetes"
  location            = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

  security_rule {
    name                       = "SSH"
    description                = "Inbound SSH Traffic"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Canal-80"
    description                = "Inbound Canal Traffic"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Canal-443"
    description                = "Inbound Secure Canal Traffic"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubeletAPI"
    description                = "Inbound Kubelet API"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "kubeproxy"
    description                = "Inbound kubeproxy"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10256"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "NodePort-Services"
    description                = "Inbound services"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "etcd"
    description                = "Inbound etcd"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

############################## PUBLIC IPS

resource "azurerm_public_ip" "rancher_publicip" {
  name                         = "rancher-publicIp"
  location                     = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  allocation_method = "Static"
}

resource "azurerm_public_ip" "kubernetes_publicip" {
  name                         = "kubernetes-publicIp"
  location                     = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  allocation_method = "Static"
}

###################################### NICs

resource "azurerm_network_interface" "rancher_nic" {
  name                      = "rancher-nic"
  location                  = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name       = "${azurerm_resource_group.resourcegroup.name}"
  network_security_group_id = "${azurerm_network_security_group.nsg_rancher.id}"

  ip_configuration {
    name                          = "rancher-ip-configuration"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    public_ip_address_id          = "${azurerm_public_ip.rancher_publicip.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_network_interface" "kubernetes_nic" {
  name                      = "kubernetes-nic"
  location                  = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name       = "${azurerm_resource_group.resourcegroup.name}"
  network_security_group_id = "${azurerm_network_security_group.nsg_kubernetes.id}"

  ip_configuration {
    name                          = "kubernetes-ip-configuration"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    public_ip_address_id          = "${azurerm_public_ip.kubernetes_publicip.id}"
    private_ip_address_allocation = "dynamic"
  }
}

##################################### Disks

resource "azurerm_managed_disk" "rancher_disk" {
  name                 = "rancher-data-disk"
  location             = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_managed_disk" "kubernetes_disk" {
  name                 = "kubernetes-data-disk"
  location             = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

###################################### VMs

resource "azurerm_virtual_machine" "rancher_machine" {
  name                             = "rancher-vm"
  location                         = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name              = "${azurerm_resource_group.resourcegroup.name}"
  network_interface_ids            = ["${azurerm_network_interface.rancher_nic.id}"]
  vm_size                          = "${var.rancher_node_vm_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${lookup(var.linux_node_image, "publisher")}"
    offer     = "${lookup(var.linux_node_image, "offer")}"
    sku       = "${lookup(var.linux_node_image, "sku")}"
    version   = "${lookup(var.linux_node_image, "version")}"
  }

  storage_os_disk {
    name              = "rancher-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.rancher_disk.name}"
    managed_disk_id = "${azurerm_managed_disk.rancher_disk.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.rancher_disk.disk_size_gb}"
  }

  os_profile {
    computer_name  = "rancher-vm"
    admin_username = "${var.administrator_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.administrator_username}/.ssh/authorized_keys"
      key_data = "${var.administrator_ssh}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl https://releases.rancher.com/install-docker/18.09.sh | sh && sudo usermod -a -G docker  ${var.administrator_username}",
      "sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher:latest"
    ]

    connection {
      type     = "ssh"
      user     = "${var.administrator_username}"
      private_key = "${file("${var.administrator_ssh_keypath}")}"
    }
  }
}

resource "azurerm_virtual_machine" "kubernetes_machine" {
  name                             = "all-${count.index}"
  location                         = "${azurerm_resource_group.resourcegroup.location}"
  resource_group_name              = "${azurerm_resource_group.resourcegroup.name}"
  network_interface_ids            = ["${azurerm_network_interface.kubernetes_nic.id}"]
  vm_size                          = "${var.kubernetes_node_vm_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${lookup(var.linux_node_image, "publisher")}"
    offer     = "${lookup(var.linux_node_image, "offer")}"
    sku       = "${lookup(var.linux_node_image, "sku")}"
    version   = "${lookup(var.linux_node_image, "version")}"
  }

  storage_os_disk {
    name              = "kubernetes-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.kubernetes_disk.name}"
    managed_disk_id = "${azurerm_managed_disk.kubernetes_disk.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.kubernetes_disk.disk_size_gb}"
  }

  os_profile {
    computer_name  = "kubernetes-vm"
    admin_username = "${var.administrator_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.administrator_username}/.ssh/authorized_keys"
      key_data = "${var.administrator_ssh}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl https://releases.rancher.com/install-docker/18.09.sh | sh && sudo usermod -a -G docker  ${var.administrator_username}",
      "${rancher2_cluster.manager.cluster_registration_token.0.node_command} --etcd --worker --controlplane"
    ]

    connection {
      type     = "ssh"
      user     = "${var.administrator_username}"
      private_key = "${file("${var.administrator_ssh_keypath}")}"
    }
  }
}