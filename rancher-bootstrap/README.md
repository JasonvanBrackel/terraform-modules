# Rancher Provisioning on Azure with Terraform and RKE

This module can be used to standup a Rancher cluster on Azure IaaS, not Azure Kubernetes Service (AKS)).  This would be a scenario where you wanted fine grained control of Kubernetes Cluster, or features that are not available from AKS.

## Warning

This module is a working in progress.  The Load Balancer components are not yet completed and will have to be compeleted after the fact.  After this process runs successfully you will have to

- Finish settting up the Azure Front End Load Balancer.
- DNS Configuration from your hostname to the Azure Front End Load Balancer.

## Future work
 - Completion of the Front End Load Balancer
 - Integration with Azure DNS

## Prerequisites

### Azure AD Service Principal

This Terraform module requires the use of an Azure Active Directory (Azure AD) Service Principal.  The configuation of this is outside of the scope of this document, but you can find more information on the document [Service Principals with Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal).

## Configuration

All of the variables for this module are set via terraform in the terraform.tfvars file.  An example file [terraform.tfvars.example](terraform.tfvars.example) has been provided as reference.

## Running

```bash
./bootstrap-rke.sh
```

### What's ths doing

- Runs terraform apply.
  - Terraform sets up the Azure Nodes.
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
- Installs Docker on each node.
- Check for Helm and downloads the requested version of Helm if needed.
- Updates the users kubeconfig file to work with this platform.
- Installs tiller and configured tiller RBAC.
- Installs Rancher.
- Installs cert-manager.
- Cleans up Kubeconfig.
