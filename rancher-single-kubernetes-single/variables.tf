variable "azure_service_principal" {
  type = "map"
  description = "Service Principal for Node Templates and the Cloud Provider configration"

  default = {
      client_id = ""
      client_secret = ""
      subscription_id = ""
      tenant_id = ""
  }
}
variable "azure_region" {
  type        = "string"
  description = "Azure region where all infrastructure will be provisioned."

  default = "East US"
}

variable "azure_resource_group" {
  type        = "string"
  description = "Name of the Azure Resource Group to be created for the network."

  default = "rancher-single-group"
}

variable "administrator_username" {
  type        = "string"
  description = "Administrator account name on the nodes."
}

variable "administrator_password" {
  type        = "string"
  description = "Administrator password on the nodes."
}

variable "administrator_ssh" {
  type        = "string"
  description = "public ssh key for the admin"
}

variable "administrator_ssh_keypath" {
  type = "string"
  description = "path to ssh private key"
}


variable "rancher_node_vm_size" {
  type        = "string"
  description = "Azure VM size of the control plane nodes"

  default = "Standard_DS2_v2"
}

variable "kubernetes_node_vm_size" {
  type        = "string"
  description = "Azure VM size of the etcd nodes"

  default = "Standard_DS2_v2"
}

variable "linux_node_image" {
  type = "map"
  description = "Image information for the Rancher Linux node"

  default = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

variable "rancher_api_url" {
  type = "string"
  description = "Endpoint for the Rancher API"

}

variable "rancher_api_token" {
  type = "string"
  description = "API Token to access the Rancher API"

}

variable "rancher_cluster_name" {
  type = "string"
  description = "Name of the rancher cluster that's being created"
}