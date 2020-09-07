#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

data_directory="$project_directory_data/generate_fasta"

prefix=$1

if [[ $# -lt 1 ]] ; then
	echo 'not enough arguments'
	echo 'call: ./${script_name} \$prefix'
	echo 'call: ./${script_name} default'
	exit 1
fi

bam_dir="$(realpath $data_directory/filtered_bam/$prefix)"
output_dir="$data_directory/fasta/$prefix"

command_bam_to_fastq="docker run --volume ${bam_dir}:/bams/ kfdrc/samtools:1.9 samtools bam2fq"
command_fastq_to_fasta="docker run --interactive biocontainers/seqtk:v1.3-1-deb_cv1 seqtk seq -A -"

mkdir -p $output_dir

trap 'echo oh, I am slain; exit' INT

for file in $bam_dir/*.bam
do
	echo "bam -> fasta: $file"
	filename_long="$(basename $file)"
	filename="${filename_long%%.*}"

	if [ -f ${output_dir}/${filename}.fasta ]; then echo "already exists (skipping)"; continue; fi

	$command_bam_to_fastq /bams/$filename_long | $command_fastq_to_fasta > ${output_dir}/${filename}.fasta.part

	if [ $? -eq 0 ]; then
		mv ${output_dir}/${filename}.fasta.part ${output_dir}/${filename}.fasta
	fi
done

