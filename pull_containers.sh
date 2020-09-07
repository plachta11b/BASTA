#!/bin/bash

script_directory=`dirname "$0"`

mkdir -p ~/singularity

containers="$($script_directory/repository.sh)"

eval $(bash $script_directory/get_daemon.sh) # return values daemon, daemon_command

pull() {

	container_short=$1; container_docker=$2; container_singularity=${3/\~/$HOME}

	if [[ $daemon == "singularity" ]]; then
		if [ ! -f $container_singularity ]; then
			$daemon_command build $container_singularity docker://$container_docker
		else
			echo "$container_singularity already exists (skipping)"
		fi
	else
		$daemon_command pull $container_docker
	fi
}

while IFS= read -r container; do pull $container </dev/null; done <<< "$containers"
