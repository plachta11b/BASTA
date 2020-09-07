#!/bin/bash

script_directory=`dirname "$0"`; config="$script_directory/project.config"

directory=$1

if [[ -z $HOME ]]; then
	echo "WARNING: \$HOME variable is not set"
fi

if [ "$directory" = "data" ]; then

	# echo 'export MF_PROJECT_DATA_DIR=/media/exhdd_2T/project_data' >> ~/.bashrc # and relog then
	# BEWARE: this environment variable override config value
	if [[ -d "$MF_PROJECT_DATA_DIR" ]]; then
		echo "$(realpath $MF_PROJECT_DATA_DIR)"
		exit 0
	fi

	dir_from_conf="$($script_directory/read_config.sh 'project_data_directory')"
	if [ ! $? -eq 0 ]; then echo $dir_from_conf; exit 1; fi
	dir_from_conf="${dir_from_conf/\~/$HOME}"

	# read and test value from config
	if [[ -d "$dir_from_conf" ]]; then
		echo "$(realpath $dir_from_conf)"
		exit 0
	fi

	echo "Project data directory does not exists. Look into $config file and set project paths"
	exit 1
elif [ "$directory" = "dataset" ]; then

	# echo 'export MF_PROJECT_DATASET_DIR=/media/exhdd_2T/project_data' >> ~/.bashrc # and relog then
	# BEWARE: this environment variable override config value
	if [[ -d "$MF_PROJECT_DATASET_DIR" ]]; then
		echo "$(realpath $MF_PROJECT_DATASET_DIR)"
		exit 0
	fi

	dir_from_conf="$($script_directory/read_config.sh 'project_dataset_directory')"
	if [ ! $? -eq 0 ]; then echo $dir_from_conf; exit 1; fi
	dir_from_conf="${dir_from_conf/\~/$HOME}"

	# read and test value from config
	if [[ -d "$dir_from_conf" ]]; then
		echo "$(realpath $dir_from_conf)"
		exit 0
	fi

	echo "Project dataset directory does not exists. Look into $config file and set project paths"
	exit 1
else
	echo "directory path fetch not implemented!"
	exit 1
fi