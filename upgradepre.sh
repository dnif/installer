#!/bin/bash
set -e


ubntu_upgrade_docker_container () {

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
	elif [[ "$1" == "pico-v9" ]]; then
                cd /DNIF/PICO
                docker-compose down
                #sed -i s/"$2"/"$3"/g /DNIF/AD/docker-compose.yaml
                docker ps
	fi



	
}



upgrade_podman_container () {

	echo "$1"
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
		container_list=( "adapter-v9" "datanode-v9" "console-v9" "core-v9" "pico-v9")
		echo -e "[-] Finding docker container"
		for container_name in "${container_list[@]}"
		do
			if [ "$(docker ps -q -f status=running -f name=^/$container_name)" ]; then
				echo -e "[-] Found $container_name docker container\n"
				echo -e "[-] Checking for current running version\n"
				sleep 3
				ver="$(docker ps  -f status=running -f name=^/$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f2)"
				echo -e "[-] Found current version $current_tag\n"
				image="$(docker ps -f status=running -f name=^/$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f1)"
				echo -e "[-] Fetching Tags from docker hub\n"
				last_tag="$(wget -q https://registry.hub.docker.com/v1/repositories/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}'|sort -V)"
				END=100
				for ((i=1;i<=END;i++)); do
					new="$(echo $last_tag|cut -d " " -f $i)"
					if [ "$new" == "$ver" ]; then
						((a=i+2))
						final="$(echo $last_tag|cut -d " " -f $a)"
						if [ "$final" ]; then
							if [ "$final" == "v9.0.6" ]; then
								final="v9.0.7"
								ubuntu_upgrade_docker_container $container_name $ver $final
								break
							else
								ubuntu_upgrade_docker_container $container_name $ver $final
								break
							fi
						else
							((b=i+1))
							final="$(echo $last_tag|cut -d " " -f $b)"
							if [ "$final" ]; then
								if [ "$final" == "v9.0.6" ]; then
									ubuntu_upgrade_docker_container $container_name $ver $final
									break
								else
									ubuntu_upgrade_docker_container $container_name $ver $final
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
		container_list=( "adapter-v9" "datanode-v9" "console-v9" "core-v9" "pico-v9")
		echo -e "[-] Finding docker container"
		for container_name in "${container_list[@]}"
		do
			if [ "$(podman ps -q -f status=running -f name=$container_name)" ]; then
				echo -e "[-] Found $container_name docker container\n"
				echo -e "[-] Checking for current running version\n"
				sleep 3
				ver="$(podman ps  -f status=running -f name=$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f2)"
				echo -e "[-] Found current version $ver\n"
				image="$(podman ps -f status=running -f name=$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f1|cut -d "/" -f3)"
				echo -e "[-] Fetching Tags from docker hub\n"
				last_tag="$(wget -q https://registry.hub.docker.com/v1/repositories/dnif/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}'|sort -V)"
				END=100
				for ((i=1;i<=END;i++)); do
					new="$(echo $last_tag|cut -d " " -f $i)"
					if [ "$new" == "$ver" ]; then
						((a=i+2))
						final="$(echo $last_tag|cut -d " " -f $a)"
						if [ "$final" ]; then
							if [ "$final" == "v9.0.6" ]; then
								final="v9.0.7"
								upgrade_podman_container $container_name $ver $final
								break
							else
								upgrade_podman_container $container_name $ver $final
								break
							fi
						else
							((b=i+1))
							final="$(echo $last_tag|cut -d " " -f $b)"
							if [ "$final" ]; then
								if [ "$final" == "v9.0.6" ]; then
									upgrade_podman_container $container_name $ver $final
									break
								else
									upgrade_podman_container $container_name $ver $final
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

