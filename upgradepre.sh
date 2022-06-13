#!/bin/bash
set -e


ubuntu_upgrade_docker_container () {

	#echo "$1"
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
	elif [[ "$1" == "pico-v9" ]]; then
                cd /DNIF/PICO
                docker-compose down
                #sed -i s/"$2"/"$3"/g /DNIF/AD/docker-compose.yaml
                docker ps
	fi



	
}



upgrade_podman_container () {

	#echo "$1"
	if [[ "$1" == "core-v9" ]]; then
                cd /DNIF
		if [[ "$2" == "v9.0" ]]; then
			curl -s "https://raw.githubusercontent.com/dnif/installer/9.0.1/license_path_change">license_path_change
			chmod +x license_path_change
			./license_path_change
			podman-compose down
		else
			podman-compose down
		fi

			podman ps
	elif [[ "$1" == "console-v9" ]]; then
                cd /DNIF/LC
                podman-compose down
                #sed -i s/"$2"/"$3"/g /DNIF/LC/docker-compose.yaml
                podman ps
	elif [[ "$1" == "datanode-v9" ]]; then
                cd /DNIF/DL
                podman-compose down
                #sed -i s/"$2"/"$3"/g /DNIF/DL/docker-compose.yaml
                podman ps
	elif [[ "$1" == "adapter-v9" ]]; then
                cd /DNIF/AD
                podman-compose down
                #sed -i s/"$2"/"$3"/g /DNIF/AD/docker-compose.yaml
                podman ps
	elif [[ "$1" == "pico-v9" ]]; then
                cd /DNIF/PICO
                podman-compose down
                #sed -i s/"$2"/"$3"/g /DNIF/AD/docker-compose.yaml
                podman ps
	fi



	
}





if [ -r /etc/os-release ]; then
	os="$(. /etc/os-release && echo "$ID")"
fi

case "${os}" in
	ubuntu)
		container_list=( "pico-v9" "adapter-v9" "datanode-v9" "console-v9" "core-v9" )
		echo -e "[-] Finding docker container"
		for container_name in "${container_list[@]}"
		do
			if [ "$(docker ps -q -f status=running -f name=^/$container_name)" ]; then
				echo -e "[-] Found $container_name docker container\n"
				echo -e "[-] Checking for current running version\n"
				sleep 3
				current_ver="$(docker ps  -f status=running -f name=^/$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f2)"
				echo -e "[-] Found current version $current_tag\n"
				image="$(docker ps -f status=running -f name=^/$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f1)"
				filtered_tag=()
				echo -e "[-] Fetching Tags from docker hub\n"
				tag_list="$(wget -q https://registry.hub.docker.com/v1/repositories/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}'|sort -V)"
				END=100
				
				for ((i=1;i<=END;i++)); do
                                        tag="$(echo $tag_list|cut -d " " -f $i)"
                                        if [[ $tag =~ ^[v9]+\.[0-9]+\.[0-9]+$ ]]; then
                                                filtered_tag+=($tag)
                                        fi
                                done
                                len=${#filtered_tag[@]}
				
				
				
				
				
				for (( i=0; i<$len; i++ )); do
					latest_ver="${filtered_tag[i]}"
					if [ "$latest_ver" == "$current_ver" ]; then
						((a=i+2))
						latest_tag=${filtered_tag[$a]}
						if [ "$latest_tag" ]; then
							if [ "$latest_tag" == "v9.0.6" ]; then
								latest_tag="v9.0.7"
								ubuntu_upgrade_docker_container $container_name $current_ver $latest_tag
								break
							else
								ubuntu_upgrade_docker_container $container_name $current_ver $latest_tag
								break
							fi
						else
							((b=i+1))
							latest_tag=${filtered_tag[$b]}
							if [ "$latest_tag" ]; then
								if [ "$latest_tag" == "v9.0.6" ]; then
									ubuntu_upgrade_docker_container $container_name $current_ver $latest_tag
									break
								else
									ubuntu_upgrade_docker_container $container_name $current_ver $latest_tag
									break
								fi
							else
								echo "up-to-date"
							fi
						fi
						break
					fi
				done
			fi
		done
			
		;;
	rhel)
		container_list=( "pico-v9" "adapter-v9" "datanode-v9" "console-v9" "core-v9" )
		echo -e "[-] Finding docker container"
		for container_name in "${container_list[@]}"
		do
			if [ "$(podman ps -q -f status=running -f name=$container_name)" ]; then
				echo -e "[-] Found $container_name docker container\n"
				echo -e "[-] Checking for current running version\n"
				sleep 3
				current_ver="$(podman ps  -f status=running -f name=$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f2)"
				echo -e "[-] Found current version $ver\n"
				image="$(podman ps -f status=running -f name=$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f1|cut -d "/" -f3)"
				echo -e "[-] Fetching Tags from docker hub\n"
				tag_list="$(wget -q https://registry.hub.docker.com/v1/repositories/dnif/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}'|sort -V)"
				filtered_tag=()
				END=100
				
				
				for ((i=1;i<=END;i++)); do
                                        tag="$(echo $tag_list|cut -d " " -f $i)"
                                        if [[ $tag =~ ^[v9]+\.[0-9]+\.[0-9]+$ ]]; then
                                                filtered_tag+=($tag)
                                        fi
                                done
                                len=${#filtered_tag[@]}
				
				
				for (( i=0; i<$len; i++ )); do
					latest_ver="${filtered_tag[i]}"
					if [ "$latest_ver" == "$current_ver" ]; then
						((a=i+2))
						latest_tag="$(echo $last_tag|cut -d " " -f $a)"
						if [ "$latest_tag" ]; then
							if [ "$latest_tag" == "v9.0.6" ]; then
								latest_tag="v9.0.7"
								upgrade_podman_container $container_name $current_ver $latest_tag
								break
							else
								upgrade_podman_container $container_name $current_ver $latest_tag
								break
							fi
						else
							((b=i+1))
							latest_tag=${filtered_tag[$b]}
							if [ "$latest_tag" ]; then
								if [ "$latest_tag" == "v9.0.6" ]; then
									upgrade_podman_container $container_name $current_ver $latest_tag
									break
								else
									upgrade_podman_container $container_name $current_ver $latest_tag
									break
								fi
							else
								echo "up-to-date"
							fi
						fi
						break
					fi
				done
			fi
		done
		;;

		esac

