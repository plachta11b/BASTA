#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`; root_dir="$script_directory/..";
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

prefix_file="$project_directory_data/generate_fasta/pipelines/prefix_filter"

exists() {
	arg_prefix=$1
	output_dir="$project_directory_data/generate_fasta/filtered_genes/$arg_prefix"
	if [ ! -d $output_dir ]; then return 1; else return 0; fi
}

exists_transcripts() {
	arg_prefix=$1
	output_dir="$project_directory_data/generate_fasta/counted_transcripts/$arg_prefix"
	if [ ! -d $output_dir ]; then return 1; else return 0; fi
}

get_region_name() {
	if [ "$1" = "5utr" ]; then echo "five_prime_UTR"; fi
	if [ "$1" = "3utr" ]; then echo "three_prime_UTR"; fi
	if [ "$1" = "coding" ]; then echo "CDS"; fi
}

mkdir -p $(dirname $prefix_file)
cat /dev/null > $prefix_file

trap 'echo oh, I am slain; exit' INT

for size in 8 16 32 64 128 256 512; do
	for region in 5utr 3utr coding; do
		prefix="dataset_balance_$(printf "%04d" ${size})x$(printf "%04d" ${size})_${region}"
		echo $prefix >> $prefix_file
		if exists $prefix; then
			echo "filter with prefix: $prefix already exist (skipping)"
		else
			$root_dir/make_filter/make_filter.sh $prefix 0.01 ${size} ${size} none EBI_GENCODE --radical
		fi
		if exists_transcripts $prefix; then
			echo "counted_transcripts with prefix: $prefix already exist (skipping)"
		else
			$root_dir/gene_to_transcript/gene_to_transcript.sh $prefix
		fi
	done
done

# big_bg_count="512"
# for size in 8 16 32 64 128 256; do
# 	for region in 5utr 3utr; do
# 		prefix="dataset_bigbg_$(printf "%04d" ${size})x$(printf "%04d" ${big_bg_count})_${region}"
# 		echo $prefix >> $prefix_file
# 		if exists $prefix; then echo "filter with prefix: $prefix already exist (skipping)"; continue; fi
# 		$script_directory/../make_filter/make_filter.sh $prefix 0.01 ${size} $big_bg_count $(get_region_name $region)
# 	done
# done

# small_bg_count="8"
# for size in 16 32 64 128 256 512; do
# 	for region in 5utr 3utr; do
# 		prefix="dataset_smallbg_$(printf "%04d" ${size})x$(printf "%04d" ${small_bg_count})_${region}"
# 		echo $prefix >> $prefix_file
# 		if exists $prefix; then echo "filter with prefix: $prefix already exist (skipping)"; continue; fi
# 		$script_directory/../make_filter/make_filter.sh $prefix 0.01 ${size} $small_bg_count $(get_region_name $region)
# 	done
# done

# testing only
# for size in 10 20 30 40 50 60 70 80 90 100; do
# 	for region in 5utr 3utr; do
# 		prefix="dataset_linear_$(printf "%04d" ${size})x$(printf "%04d" ${size})_${region}_pprsg"
# 		echo $prefix >> $prefix_file
# 	done
# done
