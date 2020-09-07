#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`

project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
data_directory="${project_directory_data}/generate_fasta"

prefix=$1

if [[ $# -lt 1 ]] ; then
    echo 'not enough arguments'
    echo 'call: ./${script_name} \$prefix'
    echo 'call: ./${script_name} default'
    exit 1
fi

trap 'echo oh, I am slain; exit' INT

out_dir=$data_directory/fasta/$prefix
mkdir -p $out_dir

docker_remove_short_sequence="docker run --interactive biocontainers/seqtk:v1.3-1-deb_cv1 seqtk seq -L 8 -"

for run in $data_directory/fasta/$prefix/*.fasta
do
	out_file=$(echo "$(dirname $run)/$(basename $run)" | sed 's/\..*//').fasta
	echo $out_file
	cat $run | $script_directory/fix_duplicate_header.awk > $out_file.temp
	cat $out_file.temp | $docker_remove_short_sequence > $out_file

	if [ $? -eq 0 ]; then rm $out_file.temp; else exit 1; fi
done
