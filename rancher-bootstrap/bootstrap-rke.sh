terraform apply --auto-approve
admin=$(terraform output -json | jq '.admin.value')8
terraform output -json | jq '.controlplane_nodes.value[],.etcd_nodes.value[],.worker_nodes.value[]' | xargs -I%  ssh -oStrictHostKeyChecking=no $admin@% 'curl https://releases.rancher.com/install-docker/17.03.sh | sh'
terraform output -json | jq '.ssh.value' | sed 's/"//g' > ssh.pub
user=$(terraform output -json | jq '.admin.value')
terraform output -json | jq '.controlplane_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$user/" -e 's/<ROLE>/controlplane/' -e 's/<PEM_FILE>/".\/ssh.pub"/'  ./node-template.yml > controlplane.yml
terraform output -json | jq '.etcd_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$user/" -e 's/<ROLE>/etcd/' -e 's/<PEM_FILE>/".\/ssh.pub"/'  ./node-template.yml > etcd.yml
terraform output -json | jq '.worker_nodes.value[]' | xargs -I{} sed -e 's/<IP>/{}/g' -e "s/<USER>/$user/" -e 's/<ROLE>/worker/' -e 's/<PEM_FILE>/".\/ssh.pub"/'  ./node-template.yml > worker.yml
cat worker.yml controlplane.yml etcd.yml > nodes.yml
sed -e '/<NODES>/ {' -e 'r nodes.yml' -e 'd' -e '}' rancher-minimal-passthrough-template.yml > config.yml
# macOS
# curl -K https://github.com/rancher/rke/releases/download/v0.1.6-rc3/rke_darwin-amd64 -o rke

# Windows
curl -K https://github.com/rancher/rke/releases/download/v0.1.6-rc3/rke -o rke.exe

chmod 700 rke
subscriptionid=$(terraform output -json | jq '.subscription_id.value') 
clientid=$(terraform output -json | jq '.client_id.value') 
clientsecret=$(terraform output -json | jq '.client_secret.value')
tenantid=$(terraform output -json | jq '.tenant_id.value') 
region=$(terraform output -json | jq '.region.value') 
subnet=$(terraform output -json | jq '.subnet.value') 
vnet=$(terraform output -json | jq '.vnet.value') 
sed -e "s/<CLIENTID>/$clientid/" -e "s/<CLIENTSECRET>/$clientsecret/" -e "s/<SUBSCRIPTIONID>/$subscriptionid/" -e "s/<TENANTID>/$tenantid/" -e "s/<REGION>/$region/" -e "s/<SUBNET>/$subnet/" -e "s/<VNET>/$vnet" azure-config-template.yml >> config.yml