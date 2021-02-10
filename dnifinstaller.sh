#!/bin/bash
ARCH=$(uname -m)
if [ "$ARCH" = "i686" ]; then
 echo -e "Upgade your system to 64 bit Architecture"
 exit 0
fi
if [ "$ARCH" = "x86_64" ]; then
 echo -e "Your Architecture is 64-Bit"
 echo -e "1. CORE \n"
 echo -e "2. DL \n"
 echo -e "3. AD \n"
 echo -e "4. LC \n"
 echo -e "5. DOCKER \n"
 echo -e "ENTER COMPONENT NAME:  \n "
 read COMP
 case ${COMP^^} in

  CORE)
    echo -e "ITS CORE..\n"
    sleep 2
    cd /
    sudo mkdir -p /dnif
    echo -e "Enter CORE IP:\c"
    read COIP
    sudo echo -e "version: "\'2.0\'"
services:
  core:
    image: dnif/core:v9beta2
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /CO:/dnif
      - /common:/common
      - /backup:/backup
    environment:
      - "\'CORE_IP=$COIP\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: core-v9">/dnif/docker-compose.yml
    cd /dnif
  #docker-compose up -d
    ;;

  DL)
    echo -e "ITS DL Need to check for OpenJdk 11\n\n"
    echo -e "Checking for JDK \n"
    if type -p java; then
	    _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
	    echo -e "\n\nfound java executable in $JAVA_HOME \n\n"
	    _java="$JAVA_HOME/bin/java"
    else
	    echo -e "\n To proceed futher you have to  Install openjdk11 before installtion\n\n"
	    echo "To install OpenJdk11 type YES"
	    read var
	    if [ $var =="YES"]; then
		    apt-get install openjdk-11-jdk
	    else
		    echo "Aborted"
		    break 
	    fi 
    fi

    if [[ "$_java" ]]; then
	    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
	    if [[ "$version" == "11.0.8" ]]; then
		    echo -e "\n OpenJdk $version version is running\n"
	    fi
    fi

		

    sleep 2
    echo -e "ENTER CORE IP: \c\n"
    read COREIP
    echo -e "\nENter INTERFACE NAME"
    read INTERFACE
    sudo mkdir -p /dnif
    sudo mkdir -p /dnif/DL
    sudo echo -e "version: "\'2\'"
services:
  datanode:
    privileged: true
    image: dnif/datanode:v9beta2
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DL:/dnif
      - /run:/run
      - /opt:/opt
      - /etc/systemd/system:/etc/systemd/system
      - /common:/common
      - /backup:/backup
    environment:
      - "\'CORE_IP=$COREIP\'"
      - "\'NET_INTERFACE=$INTERFACE\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-v9">/dnif/DL/docker-compose.yaml
      cd /dnif/DL
      #docker-compose up -d
    ;;

  AD)
    echo -e "ITS AD\n"
    echo -e "ENTER CORE IP: \c"
    read COREIP

    cd /
    sudo mkdir -p /dnif
    sudo mkdir -p /dnif/AD
    sudo echo -e "version: "\'2.0\'"
services:
 adapter:
  image: dnif/adapter:v9beta2
  network_mode: "\'host\'"
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
  environment:
   - "\'CORE_IP=$COREIP\'"
  volumes:
   - /AD:/dnif
   - /backup:/backup
  container_name: adapter-v9">/dnif/AD/docker-compose.yaml
  cd /dnif/AD
  #docker-compose up -d
    ;;
  
  LC)
    echo -e "ITS LC\n"
    echo -e "ENTER CORE IP: \c"
    read COREIP

    cd /
    sudo mkdir -p /dnif
    sudo mkdir -p /dnif/LC
    sudo echo -e "version: "\'2.0\'"
services:
 console:
  image: dnif/console:v9beta2
  network_mode: "\'host\'"
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
  environment:
   - "\'NET_INTERFACE=$COREIP\'"
  volumes:
   - /dnif/LC:/dnif/lc
  container_name: console-v9">/dnif/LC/docker-compose.yaml
  cd /dnif/LC
  #docker-compose up -d
    ;;
    
    
  DOCKER)
    echo -e "Installing docker \n"
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
    ufw reset
    ;;
       
esac
fi

