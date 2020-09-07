#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`

project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
data_directory="${project_directory_data}/generate_fasta"

prefix_old=$1
prefix_new=$2

if [[ $# -lt 2 ]] ; then
	echo "not enough arguments"
	echo "call: ./$script_name \$prefix_old \$prefix_new"
	echo "call: ./$script_name default new_prefix"
	exit 1;
fi

filtered_genes_dir=$data_directory/filtered_genes
if [ -d $filtered_genes_dir/$prefix_old ]; then
	echo "change prefix for filtered_genes"
	mv $filtered_genes_dir/$prefix_old $filtered_genes_dir/$prefix_new
fi

filtered_bam_dir=$data_directory/filtered_bam
if [ -d $filtered_bam_dir/$prefix_old ]; then
	echo "change prefix for filtered_bam"
	mv $filtered_bam_dir/$prefix_old $filtered_bam_dir/$prefix_new
fi

fasta_dir=$data_directory/fasta
if [ -d $fasta_dir/$prefix_old ]; then
	echo "change prefix for fasta"
	mv $fasta_dir/$prefix_old $fasta_dir/$prefix_new
fi
