#!/bin/bash



function docker_check() {
	
	sudo apt-get remove docker docker-engine docker.io containerd runc 
	sudo apt-get -y update &>/dev/null
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
	echo -e "[*] Installing Docker-ce\n"
	sudo apt-get -y install docker-ce docker-ce-cli containerd.io 
	sleep 5
        sudo docker run hello-world 
	echo -e "[*] Hello from Docker\n"
        sleep 5
	
	sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 
	sudo chmod +x /usr/local/bin/docker-compose 
	echo -e "[*] Installing Docker-compose - DONE\n"
        count=$(sysctl -n vm.max_map_count)
	if [ "$count" = "262144" ]; then
		echo -e "[*] Operating system fine-tuning\n"
		ufw reset 

	else

		echo -e "#memory & file settings
		fs.file-max=1000000
		vm.overcommit_memory=1
		vm.max_map_count=262144
		#n/w receive buffer
		net.core.rmem_default=33554432
		net.core.rmem_max=33554432" >>/etc/sysctl.conf

		sysctl -p
		ufw reset 
	fi

}



#echo -e "--------------------CALLING Docker------------------"

ARCH=$(uname -m)
VER=$(lsb_release -rs)


echo -e "* DNIF Installer for v9.1beta2\n"
echo -e "** for more information and code visit https://github.com/dnif-backyard/installer\n\n"

echo -e "[*] Checking operating system for compatibility...\n"


if [[ "$VER" = "20.04" ]] && [[ "$ARCH" = "x86_64" ]];  then # replace 18.04 by the number of release you want

       echo -e "[*] Compatible version\n"
       #Copy your files here
       echo -e "[*] Tested distributions and architectures\n"
       echo -e "** Ubuntu 20.04 (LTS) x86_64\n\n"
       echo -e "[*] Checking operating system for compatibility - DONE\n\n"
       echo -e "** Please report issues to https://github.com/dnif-backyard/installer/issues\n"
       echo -e "* Select a DNIF component you would like to install\n"
       echo -e "** for more information visit https://docs.dnif.it/v91/docs/high-level-dnif-architecture\n"
       echo -e "[1]- Core (CO) \n"
       echo -e "[2]- Adapter (AD) \n"
       echo -e "[3]- Console (LC) \n"
       echo -e "[4]- Data Node (DN) \n"
       echo -e "Pick the number corresponding to the component (1 - 4): "
       read -r COMP
       echo -e "-----------------------------------------------------------------------------------------"
       case "${COMP^^}" in
	       1)
		       echo -e "[*] Installing the CORE \n"
		       sleep 2
		       echo -e "[*] Finding docker installation\n"
		       if [ -x "$(command -v docker)" ]; then
			       echo -e "[*] Updating Docker\n"
			       docker_check
			else
				echo -e "[*] Finding Docker installation - NEGATIVE\n"
				echo -e "[*] Installaing Docker\n"
				docker_check
				echo -e "[*] Finding Docker installation - DONE\n"
				
			fi
			echo -e "[*] Pulling Docker Image for CORE\n"
			docker pull dnif/core:v9beta2.2 
			cd /
			sudo mkdir -p DNIF
			echo -e "Enter CORE IP:\c"
			read -r COIP
			sudo echo -e "version: "\'2.0\'"
services:
  core:
    image: dnif/core:v9beta2.2
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /CO:/dnif
      - /common:/common
      - /backup:/backup
    environment:
      - "\'CORE_IP="$COIP"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: core-v9" >/DNIF/docker-compose.yml

			      cd /DNIF || exit
			      echo -e "[*] Starting container... \n"
			      docker-compose up -d
			      echo -e "[*] Starting container... DONE\n"
			      echo -e "** Congratulations you have successfully installed the CORE\n"
			      ;;
		2)
			echo -e "[*] Installing the ADAPTER \n"
			sleep 5
			echo -e "[*] Finding Docker installation\n"
			if [ -x "$(command -v docker)" ]; then
				echo -e "[*] Updating Docker\n"
				docker_check
			else
				echo -e "[*] Finding Docker installation - NEGATIVE\n"
				echo -e "[*] Installaing Docker\n"
				docker_check
				echo -e "[*] Finding Docker installation - DONE\n"
				echo -e "[*] Finding Docker-compose - DONE\n"
				
			fi
			echo -e "[*] Pulling Docker Image for Adapter\n"
			docker pull dnif/adapter:v9beta2.2 
			echo -e "ENTER CORE IP: \c"
			read -r COREIP
			cd /
			sudo mkdir -p /DNIF
			sudo mkdir -p /DNIF/AD
			sudo echo -e "version: "\'2.0\'"
services:
 adapter:
  image: dnif/adapter:v9beta2.2
  network_mode: "\'host\'"
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
  environment:
   - "\'CORE_IP="$COREIP"\'"
  volumes:
   - /AD:/dnif
   - /backup:/backup
  container_name: adapter-v9" >/DNIF/AD/docker-compose.yml
			  cd /DNIF/AD || exit
			  echo -e "[*] Starting container...\n "
			  docker-compose up -d
			  echo -e "[*] Starting container... DONE\n"
			  echo -e "** Congratulations you have successfully installed the Adapter\n"
			  echo -e "**   Active the Adapter (10.2.1.4) from the components page\n"
			  ;;

		3)
			echo -e "[*] Installing the Local Console \n"
			sleep 5
			echo -e "[*] Finding Docker installation\n"
			if [ -x "$(command -v docker)" ]; then
				echo "[*] Updating Docker\n"
				docker_check
			else
				echo -e "[*] Finding Docker installation - NEGATIVE\n"
				echo -e "[*] Installaing Docker\n"
				docker_check
				echo -e "[*] Finding Docker installation - DONE\n"
				echo -e "[*] Finding Docker-compose - DONE\n"
			fi
			docker pull dnif/console:v9beta2.2 
			echo -e "[*] Pulling Docker Image for Local Console\n"
			echo -e "ENTER INTERFACE NAME: \c"
			read -r INTERFACE
			cd /
			sudo mkdir -p /DNIF
			sudo mkdir -p /DNIF/LC
			sudo echo -e "version: "\'2.0\'"
services:
 console:
  image: dnif/console:v9beta2.2
  network_mode: "\'host\'"
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
  environment:
   - "\'NET_INTERFACE="$INTERFACE"\'"
  volumes:
   - /dnif/LC:/dnif/lc
  container_name: console-v9" >/DNIF/LC/docker-compose.yml
			  cd /DNIF/LC || exit
			  echo -e "[*] Starting container... \n"
			  docker-compose up -d
			  echo -e "[*] Starting container... DONE\n"
			  echo -e "** Congratulations you have successfully installed the Local Console\n"
			  ;;
		4)
			echo -e "[*] Installing the DATA NODE \n"
			sleep 5
			echo -e "[*] Finding Docker installation\n"
			if [ -x "$(command -v docker)" ]; then
				echo -e "[*] Updating Docker\n"
				docker_check
			else
				echo -e "[*] Finding Docker installation - NEGATIVE\n"
				echo -e "[*] Installaing Docker\n"
				docker_check
				echo -e "[*] Finding Docker installation - DONE\n"
				echo -e "[*] Finding Docker-compose - DONE\n"
			fi
			echo -e "[*] Checking for JDK \n"
			if type -p java; then
				_java=java
			elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
				echo -e "\n\nfound java executable in $JAVA_HOME \n\n"
				_java="$JAVA_HOME/bin/java"
			else
				echo -e "\n [*]To proceed futher you have to  Install openjdk14 before installtion\n\n"
				echo "[*] To install OpenJdk14 type YES"
				read -r var
				temp=${var^^}
				if [ "$temp" == "YES" ]; then
					apt-get -y install openjdk-14-jdk 
				else
					echo "[*] Aborted"
					exit 0
				fi
			fi
			if [[ "$_java" ]]; then
				version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
				if [[ "$version" == "14.0.2" ]]; then
					echo -e "\n OpenJdk $version version is running\n"
				fi
			fi
			sleep 5
			echo -e "[*] Pulling Docker Image for Data Node\n"
			docker pull dnif/datanode:v9beta2.2
			echo -e "ENTER CORE IP: \c\n"
			read -r COREIP
			echo -e "\nENter INTERFACE NAME"
			read -r INTERFACE
			sudo mkdir -p /DNIF
			sudo mkdir -p /DNIF/DL
			sudo echo -e "version: "\'2\'"
services:
  datanode:
    privileged: true
    image: dnif/datanode:v9beta2.2
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
      - "\'CORE_IP="$COREIP"\'"
      - "\'NET_INTERFACE="$INTERFACE"\'"
    ulimits:
      memlock:
        soft: -1
         hard: -1
    container_name: datanode-v9" >/DNIF/DL/docker-compose.yml
			    cd /DNIF/DL || exit
			    echo -e "[*] Starting container... \n"
			    docker-compose up -d
			    echo -e "[*] Starting container... DONE"
			    echo -e "** Congratulations you have successfully installed the Data Node\n"
			    echo -e "**   Active the Data Node (10.2.1.4) from the components page\n"
			    ;;
		esac

	



else
       echo "Non-compatible version"
fi

