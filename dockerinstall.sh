#!/bin/bash
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get install \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg-agent \
	software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io
sleep 5
sudo docker run hello-world
sleep 5 
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo -e "#memory & file settings
fs.file-max=1000000
vm.overcommit_memory=1
vm.max_map_count=262144
#n/w receive buffer
net.core.rmem_default=33554432
net.core.rmem_max=33554432">>/etc/sysctl.conf
sysctl -p

