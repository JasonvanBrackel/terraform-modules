# Authorization Variables for the Terraform Azure Provider
variable "azure_authorization_terraform" {
  type        = "map"
  description = "Azure Service Principal under which Terraform will be executed."

  default = {
    subscription_id = ""
    client_id       = ""
    client_secret   = ""
    tenant_id       = ""
    environment     = "public"
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

  default = "rancher-group"
}

# Authorization Variables for RKE
variable "azure_authorization_rke" {
  type        = "map"
  description = "Azure Service Principal under which Rancher Kubernetes Engine will be executed."

  default = {
    subscription_id = ""
    client_id       = ""
    client_secret   = ""
    tenant_id       = ""
    environment     = "public"
  }
}

variable "worker_node_vm_size" {
  type        = "string"
  description = "Azure VM size of the worker nodes"

  default = "Standard_DS_v2"
}

variable "controlplane_node_vm_size" {
  type        = "string"
  description = "Azure VM size of the control plane nodes"

  default = "Standard_DS1_v2"
}

variable "etcd_node_vm_size" {
  type        = "string"
  description = "Azure VM size of the worker nodes"

  default = "Standard_DS1_v2"
}

# Counts of desired node types
variable "rke_worker_count" {
  type        = "string"
  description = "Number of workers to be created by Terraform."

  default = "3"
}

variable "rke_controlplane_count" {
  type        = "string"
  description = "Number of control plane nodes to be created by Terraform."

  default = "3"
}

variable "rke_etcd_count" {
  type        = "string"
  description = "Number of etcd nodes to be created by Terraform."

  default = "3"
}

# Administrator Credentials
variable "administrator_username" {
  type        = "string"
  description = "Administrator account name on the linux nodes."
}

variable "administrator_ssh" {
  type        = "string"
  description = "SSH Public Key for the Administrator account."
}

variable "administrator_ssh_private" {
  type        = "string"
  description = "The path to the SSH Private Key file."
}
