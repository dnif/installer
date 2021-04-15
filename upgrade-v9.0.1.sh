#!/bin/bash
set -e


upgrade_docker_container () {

	echo "$1"
	if [[ "$1" == "core" ]]; then
                cd /DNIF
		rm -r /DNIF/common
		echo -e "\n[-] Pulling docker Image for $1\n"
                #docker-compose down
                sed -i s/"$2"/"$3"/g /DNIF/docker-compose.yaml
                docker-compose up -d
		docker ps
	elif [[ "$1" == "console" ]]; then
                cd /DNIF/LC
		echo -e "\n[-] Pulling docker Image for $1\n"
                sed -i s/"$2"/"$3"/g /DNIF/LC/docker-compose.yaml
                docker-compose up -d
		docker ps
	elif [[ "$1" == "datanode" ]]; then
                cd /DNIF/DL
		echo -e "\n[-] Pulling docker Image for $1\n"
                sed -i s/"$2"/"$3"/g /DNIF/DL/docker-compose.yaml
                docker-compose up -d
		docker ps
	elif [[ "$1" == "adapter" ]]; then
                cd /DNIF/AD
		echo -e "\n[-] Pulling docker Image for $1\n"
                sed -i s/"$2"/"$3"/g /DNIF/AD/docker-compose.yaml
                docker-compose up -d
		docker ps
	fi



	
}



if [[ $EUID -ne 0 ]]; then
    echo -e "This script must be run as root ... \e[1;31m[ERROR] \e[0m\n"
    exit 1
else
	container_list=("core" "datanode" "adapter" "console" )
	echo -e "[-] Finding docker Image"
	for i in "${container_list[@]}"
	do
		#echo -e "[-] Finding docker Image"
		if [ "$(docker images|grep $i|awk 'NR==1 {print $1; exit}'|cut -d "/" -f2)" ]; then
			#echo -e "[-] Found $i docker container"
			echo -e "[-] Checking for current running version"
			sleep 3
			current_tag="$(docker images|grep $i|awk 'NR==1 {print $2; exit}')"
			
			echo -e "[-] Found current version $current_tag"
			image="$(docker images|grep $i|awk 'NR==1 {print $1; exit}'|cut -d "/" -f2)"
			
			echo -e "[-] Fetching Tags from docker hub"
			required_tag="$(wget -q https://registry.hub.docker.com/v1/repositories/dnif/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}'|sort -V )"
			echo -e "Enter version name from above list"
			read required
			

			if [ "$(printf '%s\n' "$required" "$current_tag" | sort -V | head -n1)" != "$required" ]; then
			
				upgrade_docker_container $i $current_tag $required
			else
				echo -e "up-to-date ${required}\n"
			fi
		fi
	done
fi


