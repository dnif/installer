#!/bin/bash
set -e

function compose_check() {
	if [ -x "$(command -v docker-compose)" ]; then
		version=$(docker-compose --version |cut -d ' ' -f3 | cut -d ',' -f1)
		if [[ "$version" != "1.23.1" ]]; then
			echo -n "[-] Finding docker-compose installation - found incompatible version"&>> /DNIF/install.log
			echo -e "... \e[0;31m[ERROR] \e[0m\n"&>> /DNIF/install.log
			echo -e "[-] Updating docker-compose\n"&>> /DNIF/install.log
			sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>> /DNIF/install.log
			sudo chmod +x /usr/local/bin/docker-compose &>> /DNIF/install.log
			echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
		else
			echo -e "[-] docker-compose up-to-date\n"&>> /DNIF/install.log
			echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
		fi
	else
		echo -e "[-] Finding docker-compose installation - ... \e[1;31m[NEGATIVE] \e[0m\n"&>> /DNIF/install.log
		echo -e "[-] Installing docker-compose\n"&>> /DNIF/install.log
		sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &>> /DNIF/install.log
		sudo chmod +x /usr/local/bin/docker-compose&>> /DNIF/install.log
        	echo -e "[-] Installing docker-compose - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
	fi

}



function docker_check() {
	echo -e "[-] Finding docker installation\n"&>> /DNIF/install.log
	if [ -x "$(command -v docker)" ]; then
		currentver="$(docker --version |cut -d ' ' -f3 | cut -d ',' -f1)"
        	requiredver="20.10.3"
        	if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
                	echo -e "[-] docker up-to-date\n"&>> /DNIF/install.log
                	echo -e "[-] Finding docker installation ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
        	else
                	echo -n "[-] Finding docker installation - found incompatible version"&>> /DNIF/install.log
                	echo -e "... \e[0;31m[ERROR] \e[0m\n"&>> /DNIF/install.log
                	echo -e "[-] Uninstalling docker\n"&>> /DNIF/install.log
                	sudo apt-get remove docker docker-engine docker.io containerd runc&>> /DNIF/install.log
                	docker_install
        	fi
	else
        	echo -e "[-] Finding docker installation - ... \e[1;31m[NEGATIVE] \e[0m\n"&>> /DNIF/install.log
        	echo -e "[-] Installing docker\n"&>> /DNIF/install.log
        	docker_install
        	echo -e "[-] Finding docker installation - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
	fi

}

function docker_install() {
	sudo apt-get -y update&>> /DNIF/install.log
	echo -e "[-] Setting up docker-ce repositories\n"&>> /DNIF/install.log
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
	echo -e "[-] Installing docker-ce\n"&>> /DNIF/install.log
	sudo apt-get -y install docker-ce docker-ce-cli containerd.io&>> /DNIF/install.log
}

function sysctl_check() {
	count=$(sysctl -n vm.max_map_count)
	if [ "$count" = "262144" ]; then
		echo -e "[-] Fine tuning the operating system\n"&>> /DNIF/install.log
		#ufw -f reset&>> /DNIF/install.log

	else

		echo -e "#memory & file settings
		fs.file-max=1000000
		vm.overcommit_memory=1
		vm.max_map_count=262144
		#n/w receive buffer
		net.core.rmem_default=33554432
		net.core.rmem_max=33554432" >>/etc/sysctl.conf
		sysctl -p

	fi

}

function set_proxy() {

	echo "HTTP_PROXY="\"$ProxyUrl"\"" >> /etc/environment
	echo "HTTPS_PROXY="\"$ProxyUrl"\"" >> /etc/environment
	echo "https_proxy="\"$ProxyUrl"\"" >> /etc/environment
	echo "http_proxy="\"$ProxyUrl"\"" >> /etc/environment
	
	export HTTP_PROXY=$ProxyUrl 
	export HTTPS_PROXY=$ProxyUrl 
	export https_proxy=$ProxyUrl 
	export http_proxy=$ProxyUrl

}

#echo -e "----------------------------------------------------------------------------------------------------------------------------------"


function podman_compose_check() {
	file="/usr/bin/podman-compose"
	if [ -f "$file" ]; then
		version=$(podman-compose version|grep "podman-composer version" |cut -d " " -f4) 
		if [[ "$version" != "0.1.7dev" ]]; then
			echo -n "[-] Finding podman-compose installation - found incompatible version"&>> /DNIF/install.log
			echo -e "... \e[0;31m[ERROR] \e[0m\n"&>> /DNIF/install.log
			echo -e "[-] Updating podman-compose\n"&>> /DNIF/install.log
			pip3 install https://github.com/containers/podman-compose/archive/devel.tar.gz&>> /DNIF/install.log
			sudo ln -s /usr/local/bin/podman-compose /usr/bin/podman-compose&>> /DNIF/install.log
			echo -e "[-] Installing podman-compose - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
		else
			echo -e "[-] podman-compose up-to-date\n"&>> /DNIF/install.log
			echo -e "[-] Installing podman-compose - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
		fi
	else
		echo -e "[-] Finding podman-compose installation - ... \e[1;31m[NEGATIVE] \e[0m\n"&>> /DNIF/install.log
		echo -e "[-] Installing podman-compose\n"&>> /DNIF/install.log
		pip3 install https://github.com/containers/podman-compose/archive/devel.tar.gz&>> /DNIF/install.log
		sudo ln -s /usr/local/bin/podman-compose /usr/bin/podman-compose&>> /DNIF/install.log
        	echo -e "[-] Installing podman-compose - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
	fi

}



function podman_check() {
	echo -e "[-] Finding podman installation\n"&>> /DNIF/install.log
	if [ -x "$(command -v podman)" ]; then
		currentver="$(podman --version|cut -d ' ' -f3)"
		requiredver="2.2.1"
		if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
			echo -e "[-] podman up-to-date\n"&>> /DNIF/install.log
			echo -e "[-] Finding podman installation ...\e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
		else
			echo -n "[-] Finding podman installation - found incompatible version"&>> /DNIF/install.log
                	echo -e "... \e[0;31m[ERROR] \e[0m\n"&>> /DNIF/install.log
                	echo -e "[-] Uninstalling podman\n"&>> /DNIF/install.log
                	podman_install
		fi
	else
		echo -e "[-] Finding podman installation - ... \e[1;31m[NEGATIVE] \e[0m\n"&>> /DNIF/install.log
        	echo -e "[-] Installing podman\n"&>> /DNIF/install.log
        	podman_install
        	echo -e "[-] Finding podman installation - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
	fi


	

}

function podman_install() {
	sudo dnf install -y @container-tools&>> /DNIF/install.log

}







if [ -r /etc/os-release ]; then
	os="$(. /etc/os-release && echo "$ID")"
fi

tag="v9.0.3"
case "${os}" in
	ubuntu)
		if [[ $EUID -ne 0 ]]; then
    echo -e "This script must be run as root ... \e[1;31m[ERROR] \e[0m\n"&>> /DNIF/install.log
    exit 1
else

	ARCH=$(uname -m)
	VER=$(lsb_release -rs)
	#tag="v9.0.3" 		# replace tag by the number of release you want
	release=$(lsb_release -ds)
	mkdir -p /DNIF
	echo -e "\nDNIF Installer for $tag\n"&>> /DNIF/install.log
	echo -e "for more information and code visit https://github.com/dnif/installer\n"&>> /DNIF/install.log

	echo -e "++ Checking operating system for compatibility...\n"&>> /DNIF/install.log

	echo -n "Operating system compatibility"&>> /DNIF/install.log
	sleep 2
	if [[ "$VER" = "20.04" ]] && [[ "$ARCH" = "x86_64" ]];  then # replace 20.04 by the number of release you want
		echo -e " ... \e[1;32m[OK] \e[0m"&>> /DNIF/install.log
		echo -n "Architecture compatibility "&>> /DNIF/install.log
		echo -e " ... \e[1;32m[OK] \e[0m\n"&>> /DNIF/install.log
		echo -e "** found $release $ARCH\n"&>> /DNIF/install.log
		echo -e "[-] Checking operating system for compatibility - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
		echo -e "** Please report issues to https://github.com/dnif/installer/issues"&>> /DNIF/install.log
		echo -e "** for more information visit https://docs.dnif.it/v9/docs/high-level-dnif-architecture\n&>> /DNIF/install.log"
		#echo -e "* Select a DNIF component you would like to install"
		#echo -e "    [1] Core (CO)"
		#echo -e "    [2] Console (LC)"
		#echo -e "    [3] Datanode (DN)"
		#	echo -e "    [4] Adapter (AD)\n"
		#COMP=""
		#while [[ ! $COMP =~ ^[1-4] ]]; do
		#	echo -e "Pick the number corresponding to the component (1 - 4):  \c"
		#	read -r COMP
		#	done
		#echo -e "-----------------------------------------------------------------------------------------"
		case $1 in
			1)
				echo -e "[-] Installing the CORE \n"&>> /DNIF/install.log
				docker_check
				compose_check
				sysctl_check
				ufw -f reset&>> /DNIF/install.log
				echo -e "------------------------------- Checking for JDK"&>> /DNIF/install.log
				apt-get -y install openjdk-14-jdk&>> /DNIF/install.log
				echo -e "\n[-] Pulling docker Image for CORE\n"&>> /DNIF/install.log
				docker pull dnif/core:$tag&>> /DNIF/install.log
				echo -e "[-] Pulling docker Image for Datanode\n"&>> /DNIF/install.log
				docker pull dnif/datanode:$tag&>> /DNIF/install.log
				cd /
				sudo mkdir -p DNIF
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
      - /DNIF/backup/core:/backup
    environment:
      - "\'CORE_IP="$2"\'"
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
      - /DNIF/backup/dn:/backup
    environment:
      - "\'CORE_IP="$2"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-master-v9">>/DNIF/docker-compose.yaml
				cd /DNIF || exit
				echo -e "[-] Starting container... \n"&>> /DNIF/install.log
				docker-compose up -d
				echo -e "[-] Starting container... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
				docker ps&>> /DNIF/install.log
				echo -e "** Congratulations you have successfully installed the CORE \n"&>> /DNIF/install.log
				;;

			2)
				echo -e "[-] Installing the Console \n"&>> /DNIF/install.log
				sleep 5
				docker_check
				compose_check
				#sysctl_check
				#ufw -f reset&>> /DNIF/install.log
				echo -e "[-] Pulling docker Image for Console\n"&>> /DNIF/install.log
				docker pull dnif/console:$tag&>> /DNIF/install.log
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
				echo -e "[-] Starting container... \n"&>> /DNIF/install.log
				docker-compose up -d
				echo -e "[-] Starting container... DONE\n"&>> /DNIF/install.log
				docker ps&>> /DNIF/install.log
				echo -e "** Congratulations you have successfully installed the Console\n"&>> /DNIF/install.log
				;;
			3)
				echo -e "[-] Installing the Datanode\n"&>> /DNIF/install.log
				docker_check
				sleep 120
				compose_check
				sysctl_check
				ufw -f reset&>> /DNIF/install.log
				apt-get -y install openjdk-14-jdk&>> /DNIF/install.log
				echo -e "\n[-] Pulling docker Image for Datanode\n"&>> /DNIF/install.log
				docker pull dnif/datanode:$tag&>> /DNIF/install.log
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
      - "\'CORE_IP="$2"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-v9">>/DNIF/DL/docker-compose.yaml
				cd /DNIF/DL
				IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
				echo -e "[-] Starting container... \n"&>> /DNIF/install.log&>> /DNIF/install.log
				docker-compose up -d
				echo -e "[-] Starting container ... \e[1;32m[DONE] \e[0m"&>> /DNIF/install.log
				docker ps&>> /DNIF/install.log
				echo -e "** Congratulations you have successfully installed the Datanode\n"&>> /DNIF/install.log
				echo -e "**   Activate the Datanode ($IP) from the components page\n"&>> /DNIF/install.log
				;;
			4)
				echo -e "[-] Installing the ADAPTER \n"&>> /DNIF/install.log
				docker_check
				sleep 120
				compose_check
				sysctl_check
				ufw -f reset&>> /DNIF/install.log
				echo -e "[-] Pulling docker Image for Adapter\n"&>> /DNIF/install.log
				docker pull dnif/adapter:$tag&>> /DNIF/install.log
				#COREIP=""
				#while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
				#	echo -e "ENTER CORE IP: \c"
				#	read -r COREIP
				#done
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
   - "\'CORE_IP="$2"\'"
   - "\'PROXY="$ProxyUrl"\'"
  volumes:
   - /DNIF/AD:/dnif
   - /DNIF/backup/ad:/backup
  container_name: adapter-v9">/DNIF/AD/docker-compose.yaml
				cd /DNIF/AD || exit
				IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
				echo -e "[-] Starting container...\n "&>> /DNIF/install.log
				docker-compose up -d
				echo -e "[-] Starting container ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
				docker ps&>> /DNIF/install.log
				echo -e "** Congratulations you have successfully installed the Adapter\n"&>> /DNIF/install.log
				echo -e "**   Activate the Adapter ($IP) from the components page\n"&>> /DNIF/install.log
				;;
			esac

	else
		echo -e "\e[0;31m[ERROR] \e[0m Operating system is incompatible"&>> /DNIF/install.log
	fi
fi



		;;
	rhel)
		if [[ $EUID -ne 0 ]]; then
    echo -e "This script must be run as root ... \e[1;31m[ERROR] \e[0m\n"&>> /DNIF/install.log
    exit 1
else

	ARCH=$(uname -m)
	VER=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
	#VER=$(lsb_release -rs)
	#tag="v9.0.3" 		# replace tag by the number of release you want
	release="$(. /etc/os-release && echo "$PRETTY_NAME")"

	mkdir -p /DNIF
	echo -e "\nDNIF Installer for $tag\n"&>> /DNIF/install.log
	echo -e "for more information and code visit https://github.com/dnif/installer\n"&>> /DNIF/install.log

	echo -e "++ Checking operating system for compatibility...\n"&>> /DNIF/install.log

	echo -n "Operating system compatibility "&>> /DNIF/install.log
	sleep 2
	if [[ "$VER" = "8.3" ]] && [[ "$ARCH" = "x86_64" ]];  then # replace 20.04 by the number of release you want
		echo -e " ... \e[1;32m[OK] \e[0m"&>> /DNIF/install.log
		echo -n "Architecture compatibility "&>> /DNIF/install.log
		echo -e " ... \e[1;32m[OK] \e[0m\n"&>> /DNIF/install.log
		echo -e "** found $release $ARCH\n"&>> /DNIF/install.log
		echo -e "[-] Checking operating system for compatibility - ... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log
		echo -e "** Please report issues to https://github.com/dnif/installer/issues"&>> /DNIF/install.log
		echo -e "** for more information visit https://docs.dnif.it/v9/docs/high-level-dnif-architecture\n"&>> /DNIF/install.log
		#echo -e "* Select a DNIF component you would like to install"
		#echo -e "    [1] Core (CO)"
		#echo -e "    [2] Console (LC)"
		#echo -e "    [3] Datanode (DN)"
		#echo -e "    [4] Adapter (AD)\n"
		#COMP=""
		#while [[ ! $COMP =~ ^[1-4] ]]; do
		#	echo -e "Pick the number corresponding to the component (1 - 4):  \c"
		#			read -r COMP
		#	done
		#echo -e "-----------------------------------------------------------------------------------------"
		case "$1" in
			1)
				echo -e "[-] Installing the CORE \n"&>> /DNIF/install.log
				podman_check
				podman_compose_check
				sysctl_check
				setenforce 0&>> /DNIF/install.log


				echo -e "[-] Checking for JDK \n"&>> /DNIF/install.log
				if type -p java; then
					_java=java
				elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
        				echo -e "[-] Found java executable in $JAVA_HOME \n"&>> /DNIF/install.log
        				_java="$JAVA_HOME/bin/java"
				else
        				#default="Y"
        				#echo -e "[-] To proceed further you have to install openjdk14 before installation\n"
        				#read -p "[-] To install OpenJdk14 type [Y/n] " var
        				#read -r var
        				#input=${var:-$default}
        				#temp=${input^^}
        				#if [ "$temp" == "Y" ]; then
					cd /usr/lib
					file="/usr/bin/wget"
					if [ ! -f "$file " ]; then
					dnf install -y wget&>> /DNIF/install.log
					dnf install -y zip&>> /DNIF/install.log
					fi
					wget https://download.java.net/java/GA/jdk14/076bab302c7b4508975440c56f6cc26a/36/GPL/openjdk-14_linux-x64_bin.tar.gz&>> /DNIF/install.log
					tar -xvf openjdk-14_linux-x64_bin.tar.gz&>> /DNIF/install.log
					echo "export JAVA_HOME=/usr/lib/jdk-14">>/etc/profile.d/jdk14.sh
					echo "export PATH=\$PATH:\$JAVA_HOME/bin">>/etc/profile.d/jdk14.sh

					source /etc/profile.d/jdk14.sh&>> /DNIF/install.log
					mkdir -p /usr/lib/jvm/&>> /DNIF/install.log
					mkdir -p /usr/lib/jvm/java-14-openjdk-amd64&>> /DNIF/install.log
					cp -r /usr/lib/jdk-14/* /usr/lib/jvm/java-14-openjdk-amd64/&>> /DNIF/install.log


        				#else
                			#	echo "[-] Aborted"
                			#	exit 0
        				#fi
				fi
				if [[ "$_java" ]]; then
        				version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
        				if [[ "$version" == "14.0.2" ]]; then
                				echo -e "[-] OpenJdk $version version is running\n"&>> /DNIF/install.log
       					fi
				fi

				mkdir -p /DNIF/CO&>> /DNIF/install.log
				mkdir -p /DNIF/common&>> /DNIF/install.log
				mkdir -p /DNIF/backup/core&>> /DNIF/install.log
				echo -e "\n[-] Pulling docker Image for CORE\n"&>> /DNIF/install.log
				sudo podman pull dnif/core:$tag&>> /DNIF/install.log

				#COREIP=""
				#while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
				#	echo -e "ENTER CORE IP: \c"
				#	read -r COREIP
				#done

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
      - /DNIF/backup/core:/backup
    environment:
      - "\'CORE_IP="$2"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: core-v9">>/DNIF/docker-compose.yaml
    				cd /DNIF
				echo -e "[-] Starting container... \n"&>> /DNIF/install.log
				podman-compose up -d
				echo -e "[-] Starting container... \e[1;32m[DONE] \e[0m\n"&>> /DNIF/install.log

    				mkdir -p /DNIF/DL&>> /DNIF/install.log
				mkdir -p /DNIF/backup/dn&>> /DNIF/install.log
				echo -e "[-] Pulling docker Image for Datanode\n"&>> /DNIF/install.log
				sudo podman pull dnif/datanode:$tag&>> /DNIF/install.log

				echo -e "version: "\'2.0\'"
services:
  datanode:
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
      - "\'CORE_IP="$2"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-v9">>/DNIF/DL/docker-compose.yaml
				cd /DNIF/DL
				echo -e "[-] Starting container... \n"&>> /DNIF/install.log
				podman-compose up -d
				echo -e "[-] Starting container ... \e[1;32m[DONE] \e[0m"&>> /DNIF/install.log




				echo -e "** Congratulations you have successfully installed the CORE \n"&>> /DNIF/install.log
				;;

			2)
				echo -e "[-] Installing the Console \n"&>> /DNIF/install.log
				podman_check
				podman_compose_check
				sysctl_check
				setenforce 0&>> /DNIF/install.log

				mkdir -p /DNIF/LC
				echo -e "[-] Pulling docker Image for Console\n"&>> /DNIF/install.log
				sudo podman pull dnif/console:$tag&>> /DNIF/install.log

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
  				echo -e "[-] Starting container... \n"&>> /DNIF/install.log
				cd /DNIF/LC
				podman-compose up -d&>> /DNIF/install.log


				echo -e "** Congratulations you have successfully installed the Console\n"&>> /DNIF/install.log
				;;
			3)
				echo -e "[-] Installing the Datanode\n"&>> /DNIF/install.log
				podman_check
				podman_compose_check
				sysctl_check
				setenforce 0&>> /DNIF/install.log


				echo -e "[-] Checking for JDK \n"&>> /DNIF/install.log
                                if type -p java; then
                                        _java=java
                                elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
                                        echo -e "[-] Found java executable in $JAVA_HOME \n"&>> /DNIF/install.log
                                        _java="$JAVA_HOME/bin/java"
                                else
                                        #default="Y"
                                        #echo -e "[-] To proceed further you have to install openjdk14 before installation\n"
                                        #read -p "[-] To install OpenJdk14 type [Y/n] " var
                                        #read -r var
                                        #input=${var:-$default}
                                        #temp=${input^^}
                                        #if [ "$temp" == "Y" ]; then
					cd /usr/lib
					file="/usr/bin/wget"
                                        if [ ! -f "$file " ]; then
						dnf install -y wget&>> /DNIF/install.log
                                        fi
                                                #dnf install -y wget
                                        wget https://download.java.net/java/GA/jdk14/076bab302c7b4508975440c56f6cc26a/36/GPL/openjdk-14_linux-x64_bin.tar.gz&>> /DNIF/install.log
                                        tar -xvf openjdk-14_linux-x64_bin.tar.gz&>> /DNIF/install.log
                                        echo "export JAVA_HOME=/usr/lib/jdk-14">>/etc/profile.d/jdk14.sh
                                        echo "export PATH=\$PATH:\$JAVA_HOME/bin">>/etc/profile.d/jdk14.sh

                                        source /etc/profile.d/jdk14.sh&>> /DNIF/install.log
                                        mkdir -p /usr/lib/jvm/&>> /DNIF/install.log
                                        mkdir -p /usr/lib/jvm/java-14-openjdk-amd64&>> /DNIF/install.log
                                        cp -r /usr/lib/jdk-14/* /usr/lib/jvm/java-14-openjdk-amd64/&>> /DNIF/install.log


                                        #else
                                        #        echo "[-] Aborted"
                                        #       exit 0
                                        #fi
                                fi
                                if [[ "$_java" ]]; then
                                        version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
                                        if [[ "$version" == "14.0.2" ]]; then
                                                echo -e "[-] OpenJdk $version version is running\n"&>> /DNIF/install.log
                                        fi
                                fi

				mkdir -p /DNIF/DL&>> /DNIF/install.log
				mkdir -p /DNIF/common&>> /DNIF/install.log
				mkdir -p /DNIF/backup/dn&>> /DNIF/install.log
				echo -e "[-] Pulling docker Image for Datanode\n"&>> /DNIF/install.log
				sudo podman pull dnif/datanode:$tag&>> /DNIF/install.log



				#COREIP=""
				#while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
				#	echo -e "ENTER CORE IP: \c"
				#	read -r COREIP
				#done

				echo -e "version: "\'2.0\'"
services:
  datanode:
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
      - "\'CORE_IP="$2"\'"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    container_name: datanode-v9">>/DNIF/DL/docker-compose.yaml
    				echo -e "[-] Starting container... \n"&>> /DNIF/install.log
				cd /DNIF/DL
				podman-compose up -d&>> /DNIF/install.log

				echo -e "** Congratulations you have successfully installed the Datanode\n"&>> /DNIF/install.log
				echo -e "**   Activate the Datanode ($IP) from the components page\n"&>> /DNIF/install.log
				;;
			4)
				echo -e "[-] Installing the ADAPTER \n"&>> /DNIF/install.log
				podman_check
				podman_compose_check
				sysctl_check
				setenforce 0&>> /DNIF/install.log
				mkdir -p /DNIF/AD&>> /DNIF/install.log
				mkdir -p /DNIF/backup/ad&>> /DNIF/install.log
				echo -e "[-] Pulling docker Image for Adapter\n"&>> /DNIF/install.log
				sudo podman pull dnif/adapter:$tag&>> /DNIF/install.log

				#COREIP=""
				#while [[ ! $COREIP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
				#	echo -e "ENTER CORE IP: \c"
				#	read -r COREIP
				#done

				sudo echo -e "version: "\'2.0\'"
services:
 adapter:
  image: dnif/adapter:$tag
  network_mode: "\'host\'"
  restart: unless-stopped
  cap_add:
   - NET_ADMIN
  environment:
   - "\'CORE_IP="$2"\'"
  volumes:
   - /DNIF/AD:/dnif
   - /DNIF/backup/ad:/backup
  container_name: adapter-v9">/DNIF/AD/docker-compose.yaml

				echo -e "[-] Starting container... \n"&>> /DNIF/install.log
				cd /DNIF/AD
				podman-compose up -d&>> /DNIF/install.log
				echo -e "** Congratulations you have successfully installed the Adapter\n"&>> /DNIF/install.log
				echo -e "**   Activate the Adapter ($IP) from the components page\n"&>> /DNIF/install.log
				;;
			esac

	else
		echo -e "\n\e[0;31m[ERROR] \e[0m Operating system is incompatible"&>> /DNIF/install.log
	fi
fi
		;;
	esac



