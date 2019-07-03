# Rancher Provisioning on Azure with Terraform and RKE

This module can be used to standup a Rancher cluster on Azure IaaS, not Azure Kubernetes Service (AKS)).  This would be a scenario where you wanted fine grained control of Kubernetes Cluster, or features that are not available from AKS.

## Prerequisites
This example uses CloudFlare DNS.  You'll need a cloudflare account with an API Key setup to allow you to change DNS records.

* You must use Terraform 0.11.x.  There are a number of issues in 0.12 and some syntax changes that cause this to fail *

### Azure AD Service Principal

This Terraform module requires the use of an Azure Active Directory (Azure AD) Service Principal.  The configuation of this is outside of the scope of this document, but you can find more information on the document [Service Principals with Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal).

## Configuration

All of the variables for this module are set via terraform in the terraform.tfvars file.  An example file [terraform.tfvars.example](terraform.tfvars.example) has been provided as reference.

## Running
Create Azure Service Principal
Setup variables file
```bash
./bootstrap-rke.sh
```

### What's ths doing

- Runs terraform apply.
  - Terraform sets up the Azure Nodes.
  - Sets up Cloudflare DNS A Record to redirecto the LB created in Azure
- Create a Service Principal for the Kubernetes Cluster.
- Runs terraform apply again to get the public ips that don't propagate immediately.
- Parses the terraform output file and creates yml files.
  - Merges node-template.yml with etcd information to create etcd.yml.
  - Merges node-template.yml with controlplane information to create controlplane.yml.
  - Merges node-template.yml with worker information to create worker.yml.
- Merges etcd.yaml, worker.yml and controlplane.yml to create nodes.yml.
- Merges nodes.yml with cluster-template.yml to create cluster.yml.
- Appends Azure Cloud Configuration to cluster.yml.
- Check for requested RKE version and downloads it if needed.
- Check for Helm and downloads the requested version of Helm if needed.
- Installs tiller and configured tiller RBAC.
- Installs Rancher.
- Installs cert-manager.
