#!/bin/bash
set -e



function upgrade_docker_container () {
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
		sed -i s/"$2"/"$3"/g /DNIF/docker-compose.yaml
		docker-compose up -d
		docker-compose logs -f| while read LREAD
		do
			if [[  `echo $LREAD | grep -o "Server is now running"` ]]; then
				((count=count+1))
				echo -e "\nBooting up container\n"
				if [[ "$count" == "2" ]]; then
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
		file=/DNIF/AD/docker-compose.yaml
		echo -e "\n[-] Pulling docker Image for $1\n"
		sed -i s/"$2"/"$3"/g /DNIF/AD/docker-compose.yaml
		if ! grep -q "tmfs" $file ; then
			sed -i '/volumes:/i\  tmpfs: /DNIF \' docker-compose.yaml
		fi
		docker-compose up -d
		docker ps
	elif [[ "$1" == "pico" ]]; then
		cd /DNIF/PICO
		file="/DNIF/PICO/docker-compose.yaml"
		if [ -f "$file" ]; then
			echo -e "\n[-] Pulling docker Image for $1\n"
			sed -i s/"$2"/"$3"/g /DNIF/PICO/docker-compose.yaml
			docker-compose up -d
			docker ps
		fi
	fi
}


function upgrade_podman_container () {

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
		sed -i s/"$2"/"$3"/g /DNIF/podman-compose.yaml
		podman-compose up -d
		podman-compose logs -f| while read LREAD
		do
			if [[  `echo $LREAD | grep -o "Server is now running"` ]]; then
				echo -e "\nBooting up container\n"
				id="$(pgrep podman-compose)"
				kill -9 $id
				break
			fi
		done
		podman ps
	elif [[ "$1" == "console" ]]; then
		cd /DNIF/LC
		echo -e "\n[-] Pulling docker Image for $1\n"
		sed -i s/"$2"/"$3"/g /DNIF/LC/podman-compose.yaml
		podman-compose up -d
		podman ps
	elif [[ "$1" == "datanode" ]]; then
		cd /DNIF/DL
		file="/DNIF/DL/podman-compose.yaml"
		if [ -f "$file" ]; then
			echo -e "\n[-] Pulling docker Image for $1\n"
			sed -i s/"$2"/"$3"/g /DNIF/DL/podman-compose.yaml
			podman-compose up -d
			podman ps
		fi
	elif [[ "$1" == "adapter" ]]; then
		cd /DNIF/AD
		file=/DNIF/AD/podman-compose.yaml
		echo -e "\n[-] Pulling docker Image for $1\n"
		sed -i s/"$2"/"$3"/g /DNIF/AD/podman-compose.yaml
		if ! grep -q "tmfs" $file ; then
			sed -i '/volumes:/i\  tmpfs: /DNIF \' podman-compose.yaml
		fi
		podman-compose up -d
		podman ps
	elif [[ "$1" == "pico" ]]; then
		cd /DNIF/PICO
		file="/DNIF/PICO/podman-compose.yaml"
		if [ -f "$file" ]; then
			echo -e "\n[-] Pulling docker Image for $1\n"
			sed -i s/"$2"/"$3"/g /DNIF/PICO/podman-compose.yaml
			podman-compose up -d
			podman ps
		fi
	fi

}


















if [ -r /etc/os-release ]; then
	os="$(. /etc/os-release && echo "$ID")"
fi

case "${os}" in
	ubuntu)
		container_list=("core" "console" "adapter" "datanode" "pico" )
		echo -e "[-] Finding docker Image"
		for container_name in "${container_list[@]}"
		do
			if [ "$(docker images|grep $container_name|awk 'NR==1 {print $1; exit}'|cut -d "/" -f2)" ]; then
				echo -e "[-] Checking for current running version"
				sleep 3
				ver="$(docker images|grep $container_name|awk 'NR==1 {print $2; exit}')"
				echo -e "[-] Found current version $current_tag"
				image="$(docker images|grep $container_name|awk 'NR==1 {print $1; exit}'|cut -d "/" -f2)"
				echo -e "[-] Fetching Tags from docker hub"
				last_tag="$(wget -q https://registry.hub.docker.com/v1/repositories/dnif/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}'|sort -V )"
				END=100
				for ((i=1;i<=END;i++)); do
					new="$(echo $last_tag|cut -d " " -f $i)"
					if [ "$new" == "$ver" ]; then
						((a=i+2))
						final="$(echo $last_tag|cut -d " " -f $a)"
						if [ "$final" ]; then
							if [ "$final" == "v9.0.6" ]; then
								final="v9.0.7"
								upgrade_docker_container $container_name $ver $final
								break
							else
								upgrade_docker_container $container_name $ver $final
								break
							fi
						else
							((b=i+1))
							final="$(echo $last_tag|cut -d " " -f $b)"
							if [ "$final" ]; then
								if [ "$final" == "v9.0.6" ]; then
									upgrade_docker_container $container_name $ver $final
									break
								else
									upgrade_docker_container $container_name $ver $final
								fi
							else
								echo -e  "[-] Up-to-date"
							fi
						fi
						break
					fi
				done
			fi
		done

		;;
	rhel)

		container_list=("core" "console" "adapter" "datanode" "pico" )
		echo -e "[-] Finding docker Image"
		for container_name in "${container_list[@]}"
		do
			if [ "$(podman images|grep $container_name|awk 'NR==1 {print $1; exit}'|cut -d "/" -f3)" ]; then
				echo -e "[-] Checking for current running version"
				sleep 3
				ver="$(podman images|grep $container_name|awk 'NR==1 {print $2; exit}')"
				echo -e "[-] Found current version $current_tag"
				image="$(podman images|grep $container_name|awk 'NR==1 {print $1; exit}'|cut -d "/" -f3)"
				echo -e "[-] Fetching Tags from docker hub"
				last_tag="$(wget -q https://registry.hub.docker.com/v1/repositories/dnif/"$image"/tags -O - | tr -d '[]" ' | tr '}' '\n' | awk -F: '{print $3}'|sort -V )"
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
								fi
							else
								echo -e  "[-] Up-to-date"
							fi
						fi
						break
					fi
				done
			fi
		done
	;;

	esac
