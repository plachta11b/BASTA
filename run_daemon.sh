#!/bin/bash

script_directory=`dirname "$0"`

docker_switches=$1; singularity_switches=$2; volumes=$3; container_short=$4; executable=$5; stdout_file_or_return=$6

containers="$($script_directory/repository.sh)"

eval $(bash $script_directory/get_daemon.sh) # return values daemon, daemon_command
container="$(echo "$containers" | grep -m 1 -w "^$container_short")"

if [[ $daemon == "singularity" ]]; then
	container="$(echo "$container" | awk '{print $3}')"
	container=${container/\~/$HOME}
	echo "singularity daemon detected, run: $container"

	if [[ ! -f $container ]]; then
		echo "build $container container first"
		exit 1
	fi

	volumes=$(echo "$volumes" | sed 's/-v  */-B\ /g')
elif [[ $daemon == "docker" ]]; then
	container="$(echo "$container" | awk '{print $2}')"
	echo "docker daemon detected, run: $container"

	# prevent multiple parallel pull calls
	if [[ "$(docker images -q $container 2> /dev/null)" == "" ]]; then
		echo "pull $container container first"
		exit 1
	fi

	volumes=$(echo "$volumes" | sed 's/-B  */-v\ /g')
else
	echo "ERROR: no container daemon detected (exit)"
	echo "$daemon $daemon_command"
	exit 1
fi

run_cmd="$($script_directory/read_config.sh "${daemon}_run_cmd")"
if [ ! $? -eq 0 ]; then echo "$run_cmd"; exit 1; fi

if [[ $daemon == "singularity" ]] && [[ "$executable" =~ .*\.sh.* ]]; then
	run_cmd=$(echo $run_cmd | sed 's/run/exec/')
fi

if [[ $stdout_file_or_return == *"return_no_run"* ]]; then
	echo "run_command: $(eval echo $run_cmd)"
else
	# expand parameters and run command
	echo "$(eval echo $run_cmd)"
	(cd $(dirname $stdout_file_or_return) && exec $(eval echo $run_cmd)) | tee $stdout_file_or_return
fi
