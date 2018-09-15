#!/bin/bash
#Provision Nodes in Azure
terraform apply -auto-approve
terraform apply # Seems to be an issue with the azure provider where publicips aren't there.  Will research later.
terraform output -json > output.json

# Grab ssh variables
admin=$(cat output.json | jq '.admin.value' | sed 's/\"//g')
private_key_path=$(cat output.json | jq '.administrator_ssh_private.value' | sed 's/\"//g')
private_key_path2=$(echo $private_key_path | sed 's/\//\\\//g')
rke_version=$(cat output.json | jq '.rke_version.value' | sed 's/\"//g')
helm_version=$(cat output.json | jq '.helm_version.value' | sed 's/\"//g')
resource_group_name=$(cat output.json | jq '.resource_group.value' | sed 's/\"//g')

# Grab rancher variables
rancher_hostname=$(cat output.json | jq '.rancher_hostname.value' | sed 's/\"//g')

# Create a Service Principal 
resource_group=$(az group show -n $resource_group_name  | jq '.id' | sed -e 's/\"//g')
subscription_id=$(echo $resource_group | awk -F/ '{print $3}')
service_principal=$(az ad sp create-for-rbac --name "$rancher_hostname" --role Contributor --scopes $resource_group --subscription $subscription_id)
client_id=$(echo $service_principal | jq '.appId') 
tenant_id=$(echo $service_principal | jq '.tenant')
client_secret=$(echo $service_principal | jq '.password')

# Create RKE Configuation Template files to be merged later
if [ -f ./etcd.yml ]; then
    rm ./etcd.yml
fi

ips=$(cat output.json | jq '.etcd_nodes.value | @csv' | sed -e 's/\\//g' -e 's/\"//g') 

index=1
for node in $(cat output.json | jq '.etcd_node_names.value[]'); do
    ip=$(echo $ips | awk -F, -v i="$index" '{print $i}')
    sed -e "s/<IP>/$ip/g" -e "s/<USER>/$admin/" -e 's/<ROLE>/etcd/'  -e "s/<PEM_FILE>/$private_key_path2/" -e "s/<HOSTNAME>/$node/" ./node-template.yml >> etcd.yml
    index=$(expr $index + 1)
done

if [ -f ./controlplane.yml ]; then
    rm ./controlplane.yml
fi

ips=$(cat output.json | jq '.controlplane_nodes.value | @csv' | sed -e 's/\\//g' -e 's/\"//g') 

index=1
for node in $(cat output.json | jq '.controlplane_node_names.value[]'); do
    ip=$(echo $ips | awk -F, -v i="$index" '{print $i}')
    sed -e "s/<IP>/$ip/g" -e "s/<USER>/$admin/" -e 's/<ROLE>/controlplane/'  -e "s/<PEM_FILE>/$private_key_path2/" -e "s/<HOSTNAME>/$node/" ./node-template.yml >> controlplane.yml
    index=$(expr $index + 1)
done

if [ -f ./worker.yml ]; then
    rm ./worker.yml
fi

ips=$(cat output.json | jq '.worker_nodes.value | @csv' | sed -e 's/\\//g' -e 's/\"//g') 

index=1
for node in $(cat output.json | jq '.worker_node_names.value[]'); do
    ip=$(echo $ips | awk -F, -v i="$index" '{print $i}')
    sed -e "s/<IP>/$ip/g" -e "s/<USER>/$admin/" -e 's/<ROLE>/worker/'  -e "s/<PEM_FILE>/$private_key_path2/" -e "s/<HOSTNAME>/$node/" ./node-template.yml >> worker.yml
    index=$(expr $index + 1)
done

# Create the RKE Cluster Configuration File
# Grab Azure Cloud Configuration Provider Variables
cat worker.yml controlplane.yml etcd.yml > nodes.yml
sed -e '/<NODES>/ {' -e 'r nodes.yml' -e 'd' -e '}' cluster-template.yml > cluster.yml
sed -e "s/<TENANTID>/$tenant_id/" -e "s/<SUBSCRIPTIONID>/$subscription_id/" -e "s/<CLIENTID>/$client_id/" -e "s/<CLIENTSECRET>/$client_secret/" azure-config-template.yml >> cluster.yml

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

# Install Docker
#cat output.json | jq '.controlplane_nodes.value[],.etcd_nodes.value[],.worker_nodes.value[]' | xargs -I%  ssh -oStrictHostKeyChecking=no -i $private_key_path $admin@% "curl https://releases.rancher.com/install-docker/17.03.sh | sh && sudo usermod -a -G docker $admin"

# Provision Kubernetes
./rke_linux-amd64 up --config ./cluster.yml

# Install Helm and Setup Tiller
# Download Helm
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

config_path="$(pwd)/kube_config_cluster.yml"

if [[ $KUBECONFIG = *"$config_path"* ]]; then
    echo "KUBECONFIG contains $config_path. Continuing."
    export NEWKUBECONFIG="$KUBECONFIG"
else
    echo "Adding $config_path to KUBECONFIG."
    export NEWKUBECONFIG="$KUBECONFIG:$config_path"
fi

echo "Temporarily chaning the KUBECONFIG file.  If something goes wrong manually change it back.  It's saved as a variable called NEWKUBECONFIG."
export KUBECONFIG="$config_path"

echo "NEWKUBECONFIG=$NEWKUBECONFIG"
echo "KUBECONFIG=$KUBECONFIG"

kubectl config set-context Default

# Setup Tiller
kubectl --kubeconfig=$(pwd)/kube_config_cluster.yml -n kube-system create serviceaccount tiller
kubectl --kubeconfig=$(pwd)/kube_config_cluster.yml create clusterrolebinding tiller \
  --clusterrole cluster-admin \
  --serviceaccount=kube-system:tiller

 cp $config_path /home/jason/snap/helm/common/kube/config

helm init --service-account tiller --kube-context Default

# Install Rancher
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable

sleep 10s

# Optional: Install Cert-Manager if you're using self-signed certificates or Let's Encrypt certificates.
helm install stable/cert-manager \
  --name cert-manager \
  --namespace kube-system \
  --kube-context Default

# Install Rancher
helm install rancher-stable/rancher \
  --name rancher \
  --namespace cattle-system \
  --set hostname=$rancher_hostname
  --kube-context Default \

# Cleanup
export KUBECONFIG="$NEWKUBECONFIG"
