#!/bin/bash

script_directory=`dirname "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

prefix_file="$project_directory_data/generate_fasta/pipelines/prefix_filter"
if [ ! -f $prefix_file ]; then echo "no prefix file (exit)"; exit 1; fi
prefixes="$(cat $prefix_file | grep "pprsg")"

out_dir="$project_directory_data/generate_fasta/fasta"

get_region_name() {
	if [[ "$1" =~ .*_5utr.* ]]; then echo "5utr"; fi
	if [[ "$1" =~ .*_3utr.* ]]; then echo "3utr"; fi
}

generate_fasta() {
	prefix=$1
	fg_size=$(echo "$prefix" | grep -o "[0-9]*x[0-9]*" | awk -F 'x' '{print $1}')
	bg_size=$(echo "$prefix" | grep -o "[0-9]*x[0-9]*" | awk -F 'x' '{print $2}')
	out_dir_final="$out_dir/$prefix"

	if [ -d ${out_dir_final} ]; then echo "already exists $prefix (skipping)"; fi

	for order in 1 2 4 8; do
		for length in 0 20 30 40 50 60 70 80 90 100; do
			$script_directory/../pprsg/run_pprsg.sh ${prefix}_temp $(get_region_name $prefix) $order $length $fg_size true
			$script_directory/../pprsg/run_pprsg.sh ${prefix}_temp $(get_region_name $prefix) $order $length $bg_size false
		done
	done

	mv ${out_dir_final}_temp ${out_dir_final}
}

trap 'echo oh, I am slain; exit' INT
while IFS= read -r prefix; do generate_fasta $prefix </dev/null; done <<< "$prefixes"
