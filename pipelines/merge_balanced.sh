#!/bin/bash

script_directory=`dirname "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

prefix_file="$project_directory_data/generate_fasta/pipelines/prefix_filter"
if [ ! -f $prefix_file ]; then echo "no prefix file (exit)"; exit 1; fi
prefixes="$(cat $prefix_file)"

out_dir="$project_directory_data/generate_fasta/fasta"

generate_fasta() {
	prefix=$1
	out_dir_final="$out_dir/$prefix"

	if [[ "$prefix" != *"dataset_balance"* ]]; then
		return
	fi

	../merge/merge.sh $prefix
}

trap 'echo oh, I am slain; exit' INT
while IFS= read -r prefix; do generate_fasta $prefix </dev/null; done <<< "$prefixes"

