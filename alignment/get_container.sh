#!/bin/bash

script_directory=`dirname "$0"`
script_name=`basename "$0"`
ref_dir=$1
data_dir=$2
output_dir=$3

eval $(bash $script_directory/../get_daemon.sh) # return values daemon, daemon_command

if [ $daemon == "singularity" ]; then container_daemon_prefix="docker://"; fi
container_bwa="${container_daemon_prefix}biocontainers/bwa:v0.7.17-3-deb_cv1"
container_samtools="${container_daemon_prefix}kfdrc/samtools:1.9"


#$daemon pull $container_bwa > /dev/null 2>&1
#$daemon pull $container_samtools > /dev/null 2>&1


if [ $daemon == "singularity" ]; then
	docker_volumes="-B ${ref_dir}:/ref_dir -B ${data_dir}:/data_dir -B ${output_dir}:/output/"
elif [ $daemon == "docker" ]; then
	docker_volumes="-v ${ref_dir}:/ref_dir -v ${data_dir}:/data_dir -v ${output_dir}:/output/"
else
	echo 'echo "unsupported container daemon"; exit 1;'
	exit 1
fi

docker_command_bwa="$daemon run -i --init ${docker_volumes} ${container_bwa} bwa"
docker_command_samtools="$daemon run -i --init ${docker_volumes} ${container_samtools} samtools"

echo $docker_command_bwa
echo $docker_command_samtools
