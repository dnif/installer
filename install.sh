#!/bin/bash
set -e


function compose_check() {
	if [ -x "$(command -v docker-compose)" ]; then
		version=$(docker-compose --version |cut -d ' ' -f3 | cut -d ',' -f1)
		if [[ "$version" != "1.23.1" ]]; then
			echo -n "[-] Finding docker-compose installation - found incompatible version"
			echo -e "... \e[0;31m[ERROR] \e[0m\n"
			echo -e "[-] Updating docker-compose\n"
			sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>> /DNIF/install.log
			sudo chmod +x /usr/local/bin/docker-compose &>> /DNIF/install.log
			echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"
		else
			echo -e "[-] docker-compose up-to-date\n"
			echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"
		fi
	else
		echo -e "[-] Finding docker-compose installation - ... \e[1;31m[NEGATIVE] \e[0m\n"
		echo -e "[-] Installing docker-compose\n"
		sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>> /DNIF/install.log
		sudo chmod +x /usr/local/bin/docker-compose&>> /DNIF/install.log
        	echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"
	fi

}



function docker_check() {
	echo -e "[-] Finding docker installation\n"
	if [ -x "$(command -v docker)" ]; then
		currentver="$(docker --version |cut -d ' ' -f3 | cut -d ',' -f1)"
        	requiredver="20.10.3"
        	if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
                	echo -e "[-] docker up-to-date\n"
                	echo -e "[-] Finding docker installation ... \e[1;32m[DONE] \e[0m\n"
        	else
                	echo -n "[-] Finding docker installation - found incompatible version"
                	echo -e "... \e[0;31m[ERROR] \e[0m\n"
                	echo -e "[-] Uninstalling docker\n"
                	sudo apt-get remove docker docker-engine docker.io containerd runc&>> /DNIF/install.log
                	docker_install
        	fi
	else
        	echo -e "[-] Finding docker installation - ... \e[1;31m[NEGATIVE] \e[0m\n"
        	echo -e "[-] Installing docker\n"
        	docker_install
        	echo -e "[-] Finding docker installation - ... \e[1;32m[DONE] \e[0m\n"
	fi

}

function docker_install() {
	sudo apt-get -y update&>> /DNIF/install.log
	echo -e "[-] Setting up docker-ce repositories\n"
	sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common&>> /DNIF/install.log
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -&>> /DNIF/install.log
	sudo apt-key fingerprint 0EBFCD88&>> /DNIF/install.log
	sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"&>> /DNIF/install.log
	sudo apt-get -y update&>> /DNIF/install.log
	echo -e "[-] Installing docker-ce\n"
	sudo apt-get -y install docker-ce docker-ce-cli containerd.io&>> /DNIF/install.log
}

function sysctl_check() {
	count=$(sysctl -n vm.max_map_count)
	if [ "$count" = "262144" ]; then
		echo -e "[-] Fine tuning the operating system\n"
		ufw -f reset&>> /DNIF/install.log

	else

		echo -e "#memory & file settings
		fs.file-max=1000000
		vm.overcommit_memory=1
		vm.max_map_count=262144
		#n/w receive buffer
		net.core.rmem_default=33554432
		net.core.rmem_max=33554432" >>/etc/sysctl.conf

		sysctl -p&>> /DNIF/install.log
		ufw -f reset&>> /DNIF/install.log
	fi

}






ARCH=$(uname -m)
VER=$(lsb_release -rs)
tag="v9.0.1" 		# replace tag by the number of release you want
release=$(lsb_release -ds)
mkdir -p /DNIF
echo -e "\nDNIF Installer for v9.0\n"
echo -e "for more information and code visit https://github.com/dnif/installer\n"

echo -e "++ Checking operating system for compatibility...\n"

echo -n "Operating system compatibility"
sleep 2
if [[ "$VER" = "20.04" ]] && [[ "$ARCH" = "x86_64" ]];  then # replace 20.04 by the number of release you want
	echo -e " ... \e[1;32m[OK] \e[0m"
	echo -n "Architecture compatibility "
	echo -e " ... \e[1;32m[OK] \e[0m\n"
	#echo -e "** found  Ubuntu 20.04 (LTS) x86_64\n"
	echo -e "** found $release $ARCH\n"
	echo -e "[-] Checking operating system for compatibility - ... \e[1;32m[DONE] \e[0m\n"
	echo -e "** Please report issues to https://github.com/dnif/installer/issues"
	echo -e "** for more information visit https://docs.dnif.it/v9/docs/high-level-dnif-architecture\n"
	echo -e "* Select a DNIF component you would like to install"
	echo -e "    [1] Core (CO)"
	echo -e "    [2] Console (LC)"
	echo -e "    [3] Datanode (DN)"
       	echo -e "    [4] Adapter (AD)\n"
	read -p "Pick the number corresponding to the component (1 - 4): " COMP
	echo -e "-----------------------------------------------------------------------------------------"
	case "${COMP^^}" in
		1)
			echo -e "[-] Installing the CORE \n"
			sleep 2
			docker_check
			compose_check
			sysctl_check
			echo -e "[-] Checking for JDK \n"
			if type -p java; then
				_java=java
			elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
				echo -e "[-] Found java executable in $JAVA_HOME \n"
				_java="$JAVA_HOME/bin/java"
			else
				default="Y"
				echo -e "[-] To proceed further you have to install openjdk14 before installation\n"
				read -p "[-] To install OpenJdk14 type [Y/n] " var
				#read -r var
				input=${var:-$default}
				temp=${input^^}
				if [ "$temp" == "Y" ]; then
					apt-get -y install openjdk-14-jdk&>> /DNIF/install.log
				else
					echo "[-] Aborted"
					exit 0
				fi
			fi
			if [[ "$_java" ]]; then
				version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
				if [[ "$version" == "14.0.2" ]]; then
					echo -e "[-] OpenJdk $version version is running\n"
				fi
			fi
			echo -e "\n[-] Pulling docker Image for CORE\n"
			docker pull dnif/core:$tag		
			echo -e "[-] Pulling docker Image for Datanode\n"
			docker pull dnif/datanode:$tag    	
			cd /
			sudo mkdir -p DNIF
			COREIP=""
			while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
				echo -e "ENTER CORE IP: \c"
				read -r COREIP
			done
			ProxyUrl=""
			while [[ ! "$ProxyUrl" ]]; do
				echo -e "ENTER Proxy url: \c"
				read -r ProxyUrl
			done
			sudo echo -e "version: "\'2.0\'"
services:
  core:
    image: dnif/core:$tag
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DNIF/CO:/dnif
      - /DNIF/common:/common
      - /DNIF/backup:/backup
    environment:
      - "\'CORE_IP="$COREIP"\'"
      - "\'proxy="$ProxyUrl"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: core-v9
  datanode-master:
    privileged: true
    image: dnif/datanode:$tag
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DNIF/DL:/dnif
      - /run:/run
      - /opt:/opt
      - /etc/systemd/system:/etc/systemd/system
      - /DNIF/common:/common
      - /DNIF/backup:/backup
    environment:
      - "\'CORE_IP="$COREIP"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-master-v9">>/DNIF/docker-compose.yaml
			cd /DNIF || exit
			echo -e "[-] Starting container... \n"
			docker-compose up -d
			echo -e "[-] Starting container... \e[1;32m[DONE] \e[0m\n"
			docker ps
			echo -e "** Congratulations you have successfully installed the CORE \n"
			;;
	
		2)
			echo -e "[-] Installing the Console \n"
			sleep 5
			docker_check
			compose_check
			sysctl_check
			echo -e "[-] Pulling docker Image for Console\n"
			docker pull dnif/console:$tag   	
			cd /
			sudo mkdir -p /DNIF
			sudo mkdir -p /DNIF/LC
			sudo echo -e "version: "\'2.0\'"
services:
 console:
  image: dnif/console:$tag
  network_mode: "\'host\'"
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
  volumes:
   - /DNIF/LC:/dnif/lc
  container_name: console-v9">/DNIF/LC/docker-compose.yaml
  			cd /DNIF/LC || exit
			echo -e "[-] Starting container... \n"
			docker-compose up -d
			echo -e "[-] Starting container... DONE\n"
			docker ps
			echo -e "** Congratulations you have successfully installed the Console\n"
			;;
		3)
			echo -e "[-] Installing the Datanode\n"
			sleep 5
			docker_check
			compose_check
			sysctl_check
			echo -e "[-] Checking for JDK \n"
			if type -p java; then
				_java=java
			elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
				echo -e "[-] Found java executable in $JAVA_HOME \n"
				_java="$JAVA_HOME/bin/java"
			else
				default="Y"
				echo -e "[-] To proceed further you have to  install openjdk14 before installation\n"
				read -p "[-] To install OpenJdk14 type [Y/n] " var
				#read -r var
				input=${var:-$default}
				temp=${input^^}
				if [ "$temp" == "Y" ]; then
					apt-get -y install openjdk-14-jdk&>> /DNIF/install.log
				else
					echo "[-] Aborted"
					exit 0
				fi
			fi
			if [[ "$_java" ]]; then
				version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
				if [[ "$version" == "14.0.2" ]]; then
					echo -e "[-] OpenJdk $version version is running\n"
				fi
			fi
			sleep 5
			echo -e "\n[-] Pulling docker Image for Datanode\n"
			docker pull dnif/datanode:$tag		
			COREIP=""
			while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
				echo -e "ENTER CORE IP: \c"
				read -r COREIP
			done
			sudo mkdir -p /DNIF
			sudo mkdir -p /DNIF/DL
			sudo echo -e "version: "\'2.0\'"
services:
  datanode:
    privileged: true
    image: dnif/datanode:$tag
    network_mode: "\'host\'"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - /DNIF/DL:/dnif
      - /run:/run
      - /opt:/opt
      - /etc/systemd/system:/etc/systemd/system
      - /DNIF/common:/common
      - /DNIF/backup:/backup
    environment:
      - "\'CORE_IP="$COREIP"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-v9">>/DNIF/DL/docker-compose.yaml
    			cd /DNIF/DL || exit
			IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
			echo -e "[-] Starting container... \n"
			docker-compose up -d
			echo -e "[-] Starting container ... \e[1;32m[DONE] \e[0m"
			docker ps
			echo -e "** Congratulations you have successfully installed the Datanode\n"
			echo -e "**   Activate the Datanode ($IP) from the components page\n"
			;;
		4)
			echo -e "[-] Installing the ADAPTER \n"
			sleep 5
			docker_check
			compose_check
			sysctl_check
			echo -e "[-] Pulling docker Image for Adapter\n"
			docker pull dnif/adapter:$tag 		
			COREIP=""
			while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
				echo -e "ENTER CORE IP: \c"
				read -r COREIP
			done
			cd /
			sudo mkdir -p /DNIF
			sudo mkdir -p /DNIF/AD
			sudo echo -e "version: "\'2.0\'"
services:
 adapter:
  image: dnif/adapter:$tag
  network_mode: "\'host\'"
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
  environment:
   - "\'CORE_IP="$COREIP"\'"
  volumes:
   - /DNIF/AD:/dnif
   - /DNIF/backup:/backup
  container_name: adapter-v9">/DNIF/AD/docker-compose.yaml
  			cd /DNIF/AD || exit
			IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
			echo -e "[-] Starting container...\n "
			docker-compose up -d
			echo -e "[-] Starting container ... \e[1;32m[DONE] \e[0m\n"
			docker ps
			echo -e "** Congratulations you have successfully installed the Adapter\n"
			echo -e "**   Activate the Adapter ($IP) from the components page\n"
			;;
		esac

else
	echo -e "\e[0;31m[ERROR] \e[0m Operating system is incompatible"
fi
