#!/bin/bash
# sudo apt-get update and sudo apt-get upgrade are two commands 
#you can use to keep all of your packages up to date in Debian or 
# a Debian-based Linux distribution. 
sudo apt-get update -y &&
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&
sudo apt-get update -y &&
sudo sudo apt-get install docker-ce docker-ce-cli containerd.io -y &&
sudo usermod -aG docker ubuntu
# install docker and last line allows you to run docker commands as the ubunu user

# A GPG (GNU Privacy Guard) key is used to ensure the authenticity of the packages that are being downloaded from Docker. 
# The key is used to sign the packages, and it serves as a way to verify that the package has not been tampered with or modified in any way. 
# This helps to ensure the security and integrity of the package, so that you can trust that you are downloading the correct package and that 
# it has not been compromised in any way.