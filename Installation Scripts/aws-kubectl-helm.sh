#!/bin/bash

echo "###################################################"
echo "AWS CLI Installing"
sudo apt install awscli -y
echo "###################################################"
echo "Kubectl Installing"
curl -L https://storage.googleapis.com/kubernetes-release/release/v1.23.6/bin/linux/amd64/kubectl --output /tmp/kubectl
sudo chmod +x ./kubectl
sudo mv /tmp/kubectl /usr/local/bin/kubectl
echo "###################################################"
echo "Installing Helm"
sudo curl -L https://git.io/get_helm.sh | bash -s -- --version v3.8.2
echo "###################################################"


