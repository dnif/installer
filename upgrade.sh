#!/bin/bash
set -e



function upgrade_docker_container () {
        #echo "$1"
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

        #echo "$1"
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
                                current_ver="$(docker images|grep $container_name|awk 'NR==1 {print $2; exit}')"
                                echo -e "[-] Found $container_name current version $current_ver"
                                image="$(docker images|grep $container_name|awk 'NR==1 {print $1; exit}'|cut -d "/" -f2)"
                                echo -e "[-] Fetching Tags from docker hub"
                                filtered_tag=()
                                tag_list="$(wget -q https://registry.hub.docker.com/v1/repositories/dnif/"$image"/tags -O - | tr -d '[]" ' |tr '}' '\n' | awk -F: '{print $3}'|sort -V )"
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
                                                #latest_tag="$(echo $filtered_tag|cut -d " " -f $a)"
                                                latest_tag=${filtered_tag[$a]}
                                                if [ "$latest_tag" ]; then
                                                        if [ "$latest_tag" == "v9.0.6" ]; then
                                                                latest_tag="v9.0.7"
                                                                upgrade_docker_container $container_name $current_ver $latest_tag
                                                                break
                                                        else
                                                                upgrade_docker_container $container_name $current_ver $latest_tag
                                                                break
                                                        fi
                                                else
                                                        ((b=i+1))
                                                        #latest_tag="$(echo $filtered_tag|cut -d " " -f $b)"
                                                        latest_tag=${filtered_tag[$b]}
                                                        if [ "$latest_tag" ]; then
                                                                if [ "$latest_tag" == "v9.0.6" ]; then
                                                                        upgrade_docker_container $container_name $current_ver $latest_tag
                                                                        break
                                                                else
                                                                        upgrade_docker_container $container_name $current_ver $latest_tag
                                                                fi
                                                        else
                                                                container_name="${container_name}-v9"

                                                                if [ "$(docker ps -q -f status=running -f name=^/$container_name)" ]; then
                                                                        running_ver="$(docker ps  -f status=running -f name=^/$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f2)"
                                                                        if [ "$running_ver" == "$latest_ver" ]; then
                                                                                echo -e  "[-] Up-to-date"
                                                                        else
                                                                                echo -e "[-] First stop $container_name container ... \e[0;31m[ERROR] \e[0m\n"
                                                                                exit 0
                                                                        fi
                                                                else
                                                                        #echo "[-] Current version is $current_ver need to overwrite $latest_ver in compose"
                                                                        if [ "$container_name" == "core-v9" ]; then
                                                                                   file="/DNIF/docker-compose.yaml"
                                                                                   if [ -f $file ]; then
                                                                                           old_ver="$(cat $file |grep "image" |cut -d ":" -f3)"
                                                                                           old_ver="$(echo $old_ver|cut -d " " -f1)"
                                                                                           if [ "$old_ver" != "$latest_ver" ]; then
                                                                                                   sed -i s/"$old_ver"/"$latest_ver"/g $file
                                                                                           fi
                                                                                           cd /DNIF
                                                                                           docker-compose up -d
                                                                                   fi
                                                                        elif [ "$container_name" == "console-v9" ]; then

                                                                                old_ver="$(cat /DNIF/LC/docker-compose.yaml |grep "image" |cut -d ":" -f3)"
                                                                                if [ "$old_ver" != "$latest_ver" ]; then
                                                                                    sed -i s/"$old_ver"/"$latest_ver"/g /DNIF/LC/docker-compose.yaml
                                                                                fi
                                                                                cd /DNIF/LC
                                                                                docker-compose up -d
                                                                        elif [ "$container_name" == "datanode-v9" ]; then
                                                                                file="/DNIF/DL/docker-compose.yaml"
                                                                                if [ -f $file ]; then
                                                                                        old_ver="$(cat $file |grep "image" |cut -d ":" -f3)"
                                                                                        if [ "$old_ver" != "$latest_ver" ]; then
                                                                                                sed -i s/"$old_ver"/"$latest_ver"/g $file
                                                                                        fi
                                                                                        cd /DNIF/DL
                                                                                        docker-compose up -d
                                                                                fi
                                                                        elif [ "$container_name" == "adapter-v9" ]; then
                                                                                old_ver="$(cat /DNIF/AD/docker-compose.yaml |grep "image" |cut -d ":" -f3)"
                                                                                if [ "$old_ver" != "$latest_ver" ]; then
                                                                                    sed -i s/"$old_ver"/"$latest_ver"/g /DNIF/AD/docker-compose.yaml
                                                                                fi
                                                                                cd /DNIF/AD
                                                                                docker-compose up -d
                                                                        elif [ "$container_name" == "pico-v9" ]; then
                                                                                old_ver="$(cat /DNIF/PICO/docker-compose.yaml |grep "image" |cut -d ":" -f3)"
                                                                                
                                                                                if [ "$old_ver" != "$latest_ver" ]; then
                                                                                    sed -i s/"$old_ver"/"$latest_ver"/g /DNIF/PICO/docker-compose.yaml
                                                                                fi
                                                                                cd /DNIF/PICO
                                                                                docker-compose up -d
                                                                        fi
                                                                        #sed -i s/"$current_ver"/"$latest_ver"/g /DNIF/docker-compose.yaml

                                                                fi
                                                        fi
                                                fi
                                                break
                                        fi
                                done
                        fi
                done

                ;;
        rhel)

                container_list=("core" "datanode" "console" "adapter" "pico" )
                echo -e "[-] Finding docker Image"
                for container_name in "${container_list[@]}"
                do
                        if [ "$(podman images|grep $container_name|awk 'NR==1 {print $1; exit}'|cut -d "/" -f3)" ]; then
                                echo -e "[-] Checking for current running version"
                                sleep 3
                                current_ver="$(podman images|grep $container_name|awk 'NR==1 {print $2; exit}')"
                                echo -e "[-] Found $container_name current version $current_ver"
                                image="$(podman images|grep $container_name|awk 'NR==1 {print $1; exit}'|cut -d "/" -f3)"
                                echo -e "[-] Fetching Tags from docker hub"
                                tag_list="$(wget -q https://registry.hub.docker.com/v1/repositories/dnif/"$image"/tags -O - | tr -d '[]" ' |tr '}' '\n' | awk -F: '{print $3}'|sort -V )"
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
                                                latest_tag=${filtered_tag[$a]}
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
                                                                fi
                                                        else
                                                                container_name="${container_name}-v9"

                                                                if [ "$(podman ps -q -f status=running -f name=$container_name)" ]; then
                                                                        running_ver="$(podman ps  -f status=running -f name=$container_name|awk 'NR > 1 {print $2; exit}'|cut -d ":" -f2)"
                                                                        if [ "$running_ver" == "$latest_ver" ]; then
                                                                                echo -e  "[-] Up-to-date"
                                                                        else
                                                                                echo -e "[-] First stop $container_name container ... \e[0;31m[ERROR] \e[0m\n"
                                                                                exit 0
                                                                        fi
                                                                else
                                                                        #echo "current version is $current_ver need to overwrite $latest_ver in compose"
                                                                        if [ "$container_name" == "core-v9" ]; then
                                                                                old_ver="$(cat /DNIF/podman-compose.yaml |grep "image" |cut -d ":" -f3)"

                                                                                #old_ver="$(echo $old_ver|cut -d " " -f1)"
                                                                                if [ "$old_ver" != "$latest_ver" ]; then
                                                                                        sed -i s/"$old_ver"/"$latest_ver"/g /DNIF/podman-compose.yaml
                                                                                fi
                                                                                cd /DNIF
                                                                                podman-compose up -d
                                                                        elif [ "$container_name" == "console-v9" ]; then
                                                                                old_ver="$(cat /DNIF/LC/podman-compose.yaml |grep "image" |cut -d ":" -f3)"
                                                                                       if [ "$old_ver" != "$latest_ver" ]; then
                                                                                    sed -i s/"$old_ver"/"$latest_ver"/g /DNIF/LC/podman-compose.yaml
                                                                                fi
                                                                                cd /DNIF/LC
                                                                                podman-compose up -d
                                                                        elif [ "$container_name" == "datanode-v9" ]; then
                                                                                old_ver="$(cat /DNIF/DL/podman-compose.yaml |grep "image" |cut -d ":" -f3)"
                                                                                if [ "$old_ver" != "$latest_ver" ]; then
                                                                                    sed -i s/"$old_ver"/"$latest_ver"/g /DNIF/DL/podman-compose.yaml
                                                                                fi
                                                                                cd /DNIF/DL
                                                                                podman-compose up -d
                                                                        elif [ "$container_name" == "adapter-v9" ]; then
                                                                                old_ver="$(cat /DNIF/AD/podman-compose.yaml |grep "image" |cut -d ":" -f3)"
                                                                                if [ "$old_ver" != "$latest_ver" ]; then
                                                                                    sed -i s/"$old_ver"/"$latest_ver"/g /DNIF/AD/podman-compose.yaml
                                                                                fi
                                                                                cd /DNIF/AD
                                                                                podman-compose up -d
                                                                        elif [ "$container_name" == "pico-v9" ]; then
                                                                                old_ver="$(cat /DNIF/PICO/podman-compose.yaml |grep "image" |cut -d ":" -f3)"
                                                                                if [ "$old_ver" != "$latest_ver" ]; then
                                                                                    sed -i s/"$old_ver"/"$latest_ver"/g /DNIF/PICO/podman-compose.yaml
                                                                                fi
                                                                                cd /DNIF/PICO
                                                                                podman-compose up -d
                                                                        fi
                                                                        #sed -i s/"$current_ver"/"$latest_ver"/g /DNIF/docker-compose.yaml

                                                                fi
                                                        fi
                                                fi
                                                break
                                        fi
                                done
                        fi
                done

        ;;

        esac
