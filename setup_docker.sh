#!/bin/bash

# do not forget allow nesting if runned inside of container
# lxc config set bio security.nesting true

sudo apt update
sudo apt-get install docker.io
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

echo "sometime system restart is needed"
echo "restart: sudo shutdown -r now"
