# Supporting Software 
# RKE Version
variable "rke_version" {
  type = "string"
  description = "version of Rancher Kubernetes Engine (RKE) used to provision Kubernetes"

  default = "v0.2.4"
}

# Helm Version
variable "helm_version" {
  type = "string"
  description = "Version of Helm to use to provision Rancher"

  default = "v2.14.1"
}

# Docker Version
variable "docker_version" {
  type = "string"
  description = "Version of Docker to use to provision Rancher"

  default = "18.09"
}


# Authorization Variables for the Terraform Azure Provider
variable "azure_service_principal" {
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

# Location
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

# Node Sizes
variable "worker_node_vm_size" {
  type        = "string"
  description = "Azure VM size of the worker nodes"

  default = "Standard_DS2_v2"
}

variable "controlplane_node_vm_size" {
  type        = "string"
  description = "Azure VM size of the control plane nodes"

  default = "Standard_DS2_v2"
}

variable "etcd_node_vm_size" {
  type        = "string"
  description = "Azure VM size of the worker nodes"

  default = "Standard_DS2_v2"
}


# Counts of desired node types for Kubernetes
variable "rke_worker_count" {
  type        = "string"
  description = "Number of workers to be created by Terraform."

  default = "1"
}

variable "rke_controlplane_count" {
  type        = "string"
  description = "Number of control plane nodes to be created by Terraform."

  default = "1"
}

variable "rke_etcd_count" {
  type        = "string"
  description = "Number of etcd nodes to be created by Terraform."

  default = "1"
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

# Rancher 
variable "rancher_hostname" {
  type = "string"
  description = "Resolvable DNS Name or IP Address of the Rancher Server"
}

variable "rancher_subdomain" {
  type = "string"
  description = "Sudomain if you're using your own DNS"
}


variable "loadbalancer_dns_label" {
  type = "string"
  description = "DNS hostname label used to create a fqdn for the frontendloadbalancer"
}


#Go Daddy (Optional)
variable "godaddy_key" {
  type = "string"
  description = "Go Daddy API Key"
}
variable "godaddy_secret" {
  type = "string"
  description = "Go Daddy API Secret"
}
variable "godaddy_domain" {
  type = "string"
  description = "Go Daddy domain to modify"
}
