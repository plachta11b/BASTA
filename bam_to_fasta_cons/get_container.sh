#!/bin/bash

script_directory=`dirname "$0"`
script_name=`basename "$0"`
ref_dir=$1
data_dir=$2

eval $(bash $script_directory/../get_daemon.sh) # return values daemon, daemon_command

if [ $daemon == "singularity" ]; then container_daemon_prefix="docker://"; fi

container_vcfutils="${container_daemon_prefix}kfdrc/vcfutils:latest"
container_seqtk="${container_daemon_prefix}biocontainers/seqtk:v1.3-1-deb_cv1"
container_bcftools="${container_daemon_prefix}biocontainers/bcftools:v1.9-1-deb_cv1"
container_samtools="${container_daemon_prefix}kfdrc/samtools:1.9"


#$daemon pull $container_vcfutils > /dev/null 2>&1
#$daemon pull $container_seqtk > /dev/null 2>&1
#$daemon pull $container_bcftools > /dev/null 2>&1
#$daemon pull $container_samtools > /dev/null 2>&1

echo "debug: $data_dir"

if [ $daemon == "singularity" ]; then
	docker_volumes="-B ${ref_dir}:/ref_dir -B ${data_dir}:/data_dir"
elif [ $daemon == "docker" ]; then
	docker_volumes="-v ${ref_dir}:/ref_dir -v ${data_dir}:/data_dir"
else
	echo 'echo "unsupported container daemon"; exit 1;'
	exit 1
fi

docker_command_vcfutils="$daemon run -i --init ${docker_volumes} ${container_vcfutils} vcfutils.pl"
docker_command_seqtk="$daemon run -i --init ${docker_volumes} ${container_seqtk} seqtk"
docker_command_bcftools="$daemon run -i --init ${docker_volumes} ${container_bcftools} bcftools"
docker_command_samtools="$daemon run -i --init ${docker_volumes} ${container_samtools} samtools"

echo $docker_command_vcfutils
echo $docker_command_seqtk
echo $docker_command_bcftools
echo $docker_command_samtools
