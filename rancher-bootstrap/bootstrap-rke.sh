#!/bin/bash
# Provision Nodes in Azure
terraform apply -auto-approve
terraform apply # Seems to be an issue with the azure provider where publicips aren't there.  Will research later.
terraform output -json > output.json

# Grab ssh variables
admin=$(cat output.json | jq '.admin.value' | sed 's/\"//g')
privatekeypath=$(cat output.json | jq '.administrator_ssh_private.value' | sed 's/\"//g')
privatekeypath2=$(echo $privatekeypath | sed 's/\//\\\//g')
rke_version=$(cat output.json | jq '.rke_version.value' | sed 's/\"//g')
helm_version=$(cat output.json | jq '.helm_version.value' | sed 's/\"//g')

# Grab Azure Cloud Configuration Provider Variables
subscriptionid=$(cat output.json | jq '.subscription_id.value') 
clientid=$(cat output.json | jq '.client_id.value') 
clientsecret=$(cat output.json | jq '.client_secret.value')
tenantid=$(cat output.json | jq '.tenant_id.value') 
region=$(cat output.json | jq '.region.value') 
subnet=$(cat output.json | jq '.subnet.value') 
vnet=$(cat output.json | jq '.vnet.value') 
resourcegroup=$(cat output.json | jq '.resourcegroup.value')

# Grab rancher variables
rancher_hostname=$(cat output.json | jq '.rancher_hostname.value' | sed 's/\"//g')

# Create RKE Configuation Template files to be merged later
cat output.json | jq '.controlplane_nodes.value[],.etcd_nodes.value[],.worker_nodes.value[]' | xargs -I%  ssh -oStrictHostKeyChecking=no -i $privatekeypath $admin@% "curl https://releases.rancher.com/install-docker/17.03.sh | sh && sudo usermod -a -G docker $admin"
cat output.json | jq '.controlplane_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$admin/" -e 's/<ROLE>/controlplane/' -e "s/<PEM_FILE>/$privatekeypath2/"  ./node-template.yml > controlplane.yml
cat output.json | jq '.etcd_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$admin/" -e 's/<ROLE>/etcd/'  -e "s/<PEM_FILE>/$privatekeypath2/" ./node-template.yml > etcd.yml
cat output.json | jq '.worker_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$admin/" -e 's/<ROLE>/worker/'  -e "s/<PEM_FILE>/$privatekeypath2/" ./node-template.yml > worker.yml

# Create the RKE Cluster Configuration File
cat worker.yml controlplane.yml etcd.yml > nodes.yml
sed -e '/<NODES>/ {' -e 'r nodes.yml' -e 'd' -e '}' cluster-template.yml > cluster.yml
sed -e "s/<TENANTID>/$tenantid/" -e "s/<SUBSCRIPTIONID>/$subscriptionid/" -e "s/<CLIENTID>/$clientid/" -e "s/<CLIENTSECRET>/$clientsecret/" azure-config-template.yml >> cluster.yml

# Grab RKE
if [ ! -f ./rke_linux-amd64 ]; then
    echo "rke not found.  Downloading from github."
    wget https://github.com/rancher/rke/releases/download/$rke_version/rke_linux-amd64
    chmod 700 ./rke_linux-amd64
else 
    if [ "rke version $rke_version" = "$(./rke_linux-amd64 -v)" ]
    then
        echo "rke version is $rke_version.  Continuing."
    else
        echo "rke version is not $rke_version.  Downloading from github."
        rm ./rke_linux-amd64
        wget https://github.com/rancher/rke/releases/download/$rke_version/rke_linux-amd64
        chmod 700 ./rke_linux-amd64
    fi
fi

# Provision Kubernetes
./rke_linux-amd64 up --config ./cluster.yml

# Install Helm and Setup Tiller
## Download Helm
if [ ! -f "./linux-amd64/helm" ]; then
    echo "Helm not found.  Downloading."
    wget https://storage.googleapis.com/kubernetes-helm/helm-$helm_version-linux-amd64.tar.gz
    tar -xvzf ./helm-$helm_version-linux-amd64.tar.gz
else
    helm_client_version=$(./linux-amd64/helm version -c --short)
    if [[ $helm_client_version = *"$helm_version"* ]]
    then
        echo "Helm version is $helm_client_version.  Continuing."
    else
        echo "Helm version is not $helm_version.  Downloading."
        rm -rf ./linux-amd64
        wget https://storage.googleapis.com/kubernetes-helm/helm-$helm_version-linux-amd64.tar.gz
        tar -xvzf ./helm-$helm_version-linux-amd64.tar.gz
    fi
fi

config_path="$(pwd)/kube_config_rancher-cluster.yml"

if [[ $KUBECONFIG = *"$config_path"* ]]; then
    echo "KUBECONFIG contains $config_path. Continuing."
else
    echo "Adding $config_path to KUBECONFIG."
fi

export KUBECONFIG="$KUBECONFIG:$(pwd)/kube_config_rancher-cluster.yml"

echo "KUBECONFIG=$KUBECONFIG"

## Setup Tiller
kubectl --kubeconfig=$(pwd)/kube_config_rancher-cluster.yml -n kube-system create serviceaccount tiller
kubectl --kubeconfig=$(pwd)/kube_config_rancher-cluster.yml create clusterrolebinding tiller \
  --clusterrole cluster-admin \
  --serviceaccount=kube-system:tiller

helm init --service-account tiller

# Install Rancher
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable

## Optional: Install Cert-Manager if you're using self-signed certificates or Let's Encrypt certificates.
helm install stable/cert-manager \
  --name cert-manager \
  --namespace kube-system

## Install Rancher
helm install rancher-stable/rancher \
  --name rancher \
  --namespace cattle-system \
  --set hostname=$rancher_hostname
