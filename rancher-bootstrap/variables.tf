# Authorization Variables for the Terraform Azure Provider
variable "azure_authorization_terraform" {
    type = "map"
    description = "Azure Service Principal under which Terraform will be executed."

    default = {
        subscription_id = ""
        client_id = ""
        client_secret = ""
        tenant_id = ""
        environment = "public"
    }
}

variable "azure_region" {
    type = "string"
    description = "Azure region where all infrastructure will be provisioned."

    default = "East US"
}

variable "azure_resource_group" {
    type = "string"
    description = "Name of the Azure Resource Group to be created for the network."

    default ="rancher-group"
}


# Authorization Variables for RKE
variable "azure_authorization_rke" {
    type = "map"
    description = "Azure Service Principal under which Rancher Kubernetes Engine will be executed."

    default = {
        subscription_id = ""
        client_id = ""
        client_secret = ""
        tenant_id = ""
        environment = "public"
    }
}

# Counts of desired node types
variable "rke_worker_count" {
    type = "string"
    description = "Number of workers to be created by Terraform."

    default = "3"
}

# Administrator Credentials
variable "administrator_name" {
    type = "string"
    description = "Administrator account name on the linux nodes."
}

variable "administrator_ssh" {
    type = "string"
    description = "SSH Public Key for the Administrator account."
}
