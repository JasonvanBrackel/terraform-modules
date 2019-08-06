#!/bin/sh

# Software versions
rancher_cli_version=$(cat output.json | jq '.rancher_cli_version.value' | sed 's/\"//g')

# Rancher Variables
rancher_hostname=$(cat output.json | jq '.rancher_hostname.value' | sed 's/\"//g')


# Download
curl -O -J -L "https://releases.rancher.com/cli2/$rancher_cli_version/rancher-linux-amd64-$rancher_cli_version.tar.gz"

# Untar
tar -xvzf ./"rancher-linux-amd64-$rancher_cli_version.tar.gz"

# Copy
cp ./rancher-$rancher_cli_version/rancher /usr/local/bin/

# Login using the api token created during initialization
rancher login -t $admin_api_token -n $rancher_hostname "https://$rancher_hostname/v3"