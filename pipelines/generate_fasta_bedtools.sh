#!/bin/bash

script_directory=`dirname "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

source=${1:-reference}

if [[ $# -lt 1 ]] ; then
	echo 'not enough arguments'
	echo 'call: ./${script_name} [\$source=reference]'
	echo 'call: ./${script_name} [reference|bams]'
	exit 1
fi

prefix_file="$project_directory_data/generate_fasta/pipelines/prefix_filter"
if [ ! -f $prefix_file ]; then echo "no prefix file (exit)"; exit 1; fi
prefixes="$(cat $prefix_file)"

out_dir="$project_directory_data/generate_fasta/fasta"

get_region_name() {
	if [[ "$1" =~ .*_5utr.* ]]; then echo "5utr"; fi
	if [[ "$1" =~ .*_3utr.* ]]; then echo "3utr"; fi
}

generate_fasta() {
	prefix=$1
	in="${prefix}"
	out="${prefix}_bt_${source}"

	if [ -d ${out_dir}/${out} ]; then echo "already exists ${prefix} (skipping)"; return 0; fi

	if [ "$source" = "bams" ]; then
		${script_directory}/../cons_to_fasta/liftover.sh ${prefix} ${prefix}_bt_${source} ${source}
		if [ $? -ne 0 ]; then echo "exiting lifting due to non-zero code"; exit 1; fi
	fi

	${script_directory}/../cons_to_fasta/cut_all.sh ${prefix} ${prefix}_bt_${source} ${source}
	if [ $? -ne 0 ]; then echo "exiting sequence cutting due to non-zero code"; exit 1; fi

}

trap 'echo oh, I am slain; exit' INT
while IFS= read -r prefix; do generate_fasta ${prefix} </dev/null; done <<< "$prefixes"
