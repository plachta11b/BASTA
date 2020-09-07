#!/bin/bash

script_directory=`dirname "$0"`

config_key=$1

# "EOM" dissalow param expansion
# EOM alow param expansion
read -r -d '' default_config << "EOM"
	project_data_directory: /path/to/project/data
	project_dataset_directory: /path/to/project/dataset/eIF4E
	# container daemon
	docker_run_cmd: $daemon_command run --init $docker_switches $volumes $container $executable
	singularity_run_cmd: $daemon_command run -C $singularity_switches $volumes $container "$executable"
EOM

default_config=$(echo "$default_config")

config_file="$script_directory/project.config"

if [ ! -f $config_file ]; then
	echo "$default_config" | awk '{$1=$1;print}' > $config_file
fi

# used only for config file creation
if [ "$config_key" = "init" ]; then exit 0; fi

config_value="$(cat $config_file | grep -F "$config_key: " | sed "s/$config_key: *//")"
if [ ! $? -eq 0 ] || [ -z "$config_value" ]; then
	config_value="$(echo "$default_config" | grep -F "$config_key: " | sed "s/$config_key: *//")"
	if [ ! $? -eq 0 ] || [ -z "$config_value" ]; then
		echo "$config_value"; exit 1;
	fi
fi

# awk to trim whitespace from start
echo "$config_value" | awk '{$1=$1;print}'
