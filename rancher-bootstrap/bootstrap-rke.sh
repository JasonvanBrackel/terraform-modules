#!/bin/bash
terraform apply -auto-approve
terraform apply # Seems to be an issue with the azure provider where publicips aren't there.  Will research later.
terraform output -json > output.json
admin=$(cat output.json | jq '.admin.value' | sed 's/\"//g')
privatekeypath=$(cat output.json | jq '.administrator_ssh_private.value' | sed 's/\"//g')
privatekeypath2=$(echo $privatekeypath | sed 's/\//\\\//g')
cat output.json | jq '.controlplane_nodes.value[],.etcd_nodes.value[],.worker_nodes.value[]' | xargs -I%  ssh -oStrictHostKeyChecking=no -i $privatekeypath $admin@% "curl https://releases.rancher.com/install-docker/17.03.sh | sh && sudo usermod -a -G docker $admin"
cat output.json | jq '.controlplane_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$admin/" -e 's/<ROLE>/controlplane/' -e "s/<PEM_FILE>/$privatekeypath2/"  ./node-template.yml > controlplane.yml
cat output.json | jq '.etcd_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$admin/" -e 's/<ROLE>/etcd/'  -e "s/<PEM_FILE>/$privatekeypath2/" ./node-template.yml > etcd.yml
cat output.json | jq '.worker_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$admin/" -e 's/<ROLE>/worker/'  -e "s/<PEM_FILE>/$privatekeypath2/" ./node-template.yml > worker.yml
cat worker.yml controlplane.yml etcd.yml > nodes.yml
sed -e '/<NODES>/ {' -e 'r nodes.yml' -e 'd' -e '}' cluster-template.yml > cluster.yml
wget https://github.com/rancher/rke/releases/download/v0.1.8/rke_linux-amd64
chmod 700 ./rke_linux-amd64
subscriptionid=$(cat output.json | jq '.subscription_id.value') 
clientid=$(cat output.json | jq '.client_id.value') 
clientsecret=$(cat output.json | jq '.client_secret.value')
tenantid=$(cat output.json | jq '.tenant_id.value') 
region=$(cat output.json | jq '.region.value') 
subnet=$(cat output.json | jq '.subnet.value') 
vnet=$(cat output.json | jq '.vnet.value') 
resourcegroup=$(cat output.json | jq '.resourcegroup.value')
#sed -e "s/<CLIENTID>/$clientid/" -e "s/<CLIENTSECRET>/$clientsecret/" -e "s/<SUBSCRIPTIONID>/$subscriptionid/" -e "s/<TENANTID>/$tenantid/" -e "s/<REGION>/$region/" -e "s/<SUBNET>/$subnet/" -e "s/<VNET>/$vnet/" -e "s/<RESOURCEGROUP>/$resourcegroup/" azure-config-template.yml >> cluster.yml
sed -e "s/<TENANTID>/$tenantid/" -e "s/<SUBSCRIPTIONID>/$subscriptionid/" -e "s/<CLIENTID>/$clientid/" -e "s/<CLIENTSECRET>/$clientsecret/" azure-config-template.yml >> cluster.yml
./rke_linux-amd64 up
