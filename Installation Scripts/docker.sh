#!/bin/bash

echo "Installing docker"
sudo apt-get update
sudo apt-get install docker.io -y
sudo apt-get install docker-compose -y
sudo usermod -aG docker $USER   #my case is ubuntu
newgrp docker
sudo chmod 777 /var/run/docker.sock
