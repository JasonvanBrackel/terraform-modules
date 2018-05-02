#!/bin/bash
terraform apply -auto-approve
terraform apply # Seems to be an issue with the azure provider where publicips aren't there.  Will research later.
terraform output
admin=$(terraform output -json | jq '.admin.value' | sed 's/\"//g')
privatekeypath=$(terraform output -json | jq '.administrator_ssh_private.value' | sed 's/\"//g')
terraform output -json | jq '.controlplane_nodes.value[],.etcd_nodes.value[],.worker_nodes.value[]' | xargs -I%  ssh -oStrictHostKeyChecking=no -i $privatekeypath $admin@% 'curl https://releases.rancher.com/install-docker/17.03.sh | sh'
terraform output -json | jq '.ssh.value' | sed 's/\"//g' > ssh.pub
terraform output -json | jq '.controlplane_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$admin/" -e 's/<ROLE>/controlplane/' -e 's/<PEM_FILE>/".\/id_rsa"/'  ./node-template.yml > controlplane.yml
terraform output -json | jq '.etcd_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$admin/" -e 's/<ROLE>/etcd/' -e 's/<PEM_FILE>/".\/id_rsa"/'  ./node-template.yml > etcd.yml
terraform output -json | jq '.worker_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$admin/" -e 's/<ROLE>/worker/' -e 's/<PEM_FILE>/".\/id_rsa"/'  ./node-template.yml > worker.yml
cat worker.yml controlplane.yml etcd.yml > nodes.yml
sed -e '/<NODES>/ {' -e 'r nodes.yml' -e 'd' -e '}' rancher-minimal-passthrough-template.yml > cluster.yml
wget -o rke https://github.com/rancher/rke/releases/download/v0.1.6/rke_linux-amd64
mv ./rke_linux-amd64 rke
chmod 700 rke
subscriptionid=$(terraform output -json | jq '.subscription_id.value') 
clientid=$(terraform output -json | jq '.client_id.value') 
clientsecret=$(terraform output -json | jq '.client_secret.value')
tenantid=$(terraform output -json | jq '.tenant_id.value') 
region=$(terraform output -json | jq '.region.value') 
subnet=$(terraform output -json | jq '.subnet.value') 
vnet=$(terraform output -json | jq '.vnet.value') 
resourcegroup=$(terraform output -json | jq '.resourcegroup.value')
sed -e "s/<CLIENTID>/$clientid/" -e "s/<CLIENTSECRET>/$clientsecret/" -e "s/<SUBSCRIPTIONID>/$subscriptionid/" -e "s/<TENANTID>/$tenantid/" -e "s/<REGION>/$region/" -e "s/<SUBNET>/$subnet/" -e "s/<VNET>/$vnet/" -e "s/<RESOURCEGROUP>/$resourcegroup/" azure-config-template.yml >> cluster.yml
rke up