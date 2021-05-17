#!/bin/bash
set -e


upgrade_docker_container () {

	echo "$1"
	if [[ "$1" == "core" ]]; then
                cd /DNIF
		rm -r /DNIF/common
		if [[ "$3" == "v9.0.3" ]]; then
			file="/DNIF/CO/redis/data/dump.rdb"
			if [ -f "$file" ]; then
				mv /DNIF/CO/redis/data/dump.rdb /DNIF/CO/redis/data/dump.rdb_backup
			fi
		fi
		echo -e "\n[-] Pulling docker Image for $1\n"
                #docker-compose down
                sed -i s/"$2"/"$3"/g /DNIF/docker-compose.yaml
                docker-compose up -d
		docker-compose logs -f| while read LREAD
		do
			if [[  `echo $LREAD | grep -o "Server is now running"` ]]; then
				((i=i+1))
				echo -e "\nBooting up container\n"
				if [[ "$i" == "2" ]]; then
					id="$(pidof docker-compose)"
					kill -9 $id
					exit 0
				fi
			fi
		done

		docker ps
	elif [[ "$1" == "console" ]]; then
                cd /DNIF/LC
		echo -e "\n[-] Pulling docker Image for $1\n"
                sed -i s/"$2"/"$3"/g /DNIF/LC/docker-compose.yaml
                docker-compose up -d
		docker ps
	elif [[ "$1" == "datanode" ]]; then
                cd /DNIF/DL
		file="/DNIF/DL/docker-compose.yaml"
		if [ -f "$file" ]; then
			echo -e "\n[-] Pulling docker Image for $1\n"
                	sed -i s/"$2"/"$3"/g /DNIF/DL/docker-compose.yaml
                	docker-compose up -d
			docker ps
		fi
	elif [[ "$1" == "adapter" ]]; then
                cd /DNIF/AD
		echo -e "\n[-] Pulling docker Image for $1\n"
                sed -i s/"$2"/"$3"/g /DNIF/AD/docker-compose.yaml
		sed -i '/volumes:/i\  tmpfs: /DNIF \' docker-compose.yaml
                docker-compose up -d
		docker ps
	fi



	
}



if [[ $EUID -ne 0 ]]; then
    echo -e "This script must be run as root ... \e[1;31m[ERROR] \e[0m\n"
    exit 1
else
	container_list=("core" "console" "adapter" "datanode" )
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
			#required_tag="$(wget -q https://registry.hub.docker.com/v1/repositories/dnif/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}'|sort -V )"
			if [ "$current_tag" == "v9.0" ]; then
				required_tag="v9.0.1"
				upgrade_docker_container $i $current_tag $required_tag
			elif [ "$current_tag" == "v9.0.1" ]; then
				required_tag="v9.0.3"
				upgrade_docker_container $i $current_tag $required_tag
			elif [ "$current_tag" == "v9.0.2" ]; then
                                required_tag="v9.0.4"
                                upgrade_docker_container $i $current_tag $required_tag
			elif [ "$current_tag" == "v9.0.3" ]; then
                                required_tag="v9.0.4"
                                upgrade_docker_container $i $current_tag $required_tag
			else
				echo -e "up-to-date ${required}\n"
			fi
		fi
	done
fi

