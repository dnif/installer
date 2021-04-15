#!/bin/bash
set -e


upgrade_docker_container () {

	echo "$1"
	if [[ "$1" == "core-v9" ]]; then
                cd /DNIF
		if [[ "$2" == "v9.0" ]]; then
			curl -s "https://raw.githubusercontent.com/dnif/installer/9.0.1/license_path_change">license_path_change
			chmod +x license_path_change
			./license_path_change
			docker-compose down
		else
			docker-compose down
		fi

			docker ps
	elif [[ "$1" == "console-v9" ]]; then
                cd /DNIF/LC
                docker-compose down
                #sed -i s/"$2"/"$3"/g /DNIF/LC/docker-compose.yaml
                docker ps
	elif [[ "$1" == "datanode-v9" ]]; then
                cd /DNIF/DL
                docker-compose down
                #sed -i s/"$2"/"$3"/g /DNIF/DL/docker-compose.yaml
                docker ps
	elif [[ "$1" == "adapter-v9" ]]; then
                cd /DNIF/AD
                docker-compose down
                #sed -i s/"$2"/"$3"/g /DNIF/AD/docker-compose.yaml
                docker ps
	fi



	
}


if [[ $EUID -ne 0 ]]; then
    echo -e "This script must be run as root ... \e[1;31m[ERROR] \e[0m\n"
    exit 1
else
	container_list=( "adapter-v9" "datanode-v9" "console-v9" "core-v9")
	echo -e "[-] Finding docker container"
	for i in "${container_list[@]}"
	do
		#echo -e "[-] Finding docker container"
		if [ "$(docker ps -q -f status=running -f name=^/$i)" ]; then


			echo -e "[-] Found $i docker container\n"
			echo -e "[-] Checking for current running version\n"
			sleep 3
			current_tag="$(docker ps  -f status=running -f name=^/$i|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f2)"
			
			echo -e "[-] Found current version $current_tag\n"
			image="$(docker ps -f status=running -f name=^/$i|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f1)"
			
			#Tags=( "$(wget -q https://registry.hub.docker.com/v1/repositories/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}')")
			echo -e "[-] Fetching Tags from docker hub\n"
			required_tag="$(wget -q https://registry.hub.docker.com/v1/repositories/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}'|sort -V|awk 'END{print}')"
			
			if [ "$(printf '%s\n' "$required_tag" "$current_tag" | sort -V | head -n1)" != "$required_tag" ]; then
				
				upgrade_docker_container $i $current_tag $required_tag

			else
				echo "Found updated version ${required_tag}"
			fi

			
		fi

	done
fi


