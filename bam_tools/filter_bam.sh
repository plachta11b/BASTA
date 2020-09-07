#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

data_directory="$project_directory_data/generate_fasta"

arg_prefix=$1
arg_format=$2
arg_prefiltered=$3
# todo add bam sorting, indexing

if [[ $# -lt 3 ]] ; then
	echo "not enough arguments"
	echo "call: ./$script_name \$prefix \$format \$prefiltered"
	echo "default call: ./$script_name default bam|sam|both false"
	exit 1
fi

echo "./$script_name prefix=$arg_prefix format=$arg_format prefiltered=$arg_prefiltered"

bam_dir="$data_directory/source_data/bam"
prefiltered_bam_dir="$data_directory/prefiltered_bam/0_01/bam"
filter_dir="$data_directory/filtered_genes/$arg_prefix"
output_dir="$data_directory/filtered_bam/$arg_prefix"

rep2="HLF2VBGX7_.*.bam$"
rep3="HVH5TBGX7_.*.bam$"
rep4="HVGWYBGX7_.*.bam$"

replicate_array=($rep2 $rep3 $rep4)
bam_files=()
for replicate in "${replicate_array[@]}"
do
	#echo $replicate
	for covrun_file in $(ls $bam_dir | grep -e "$replicate")
	do
		bam_files+=("$bam_dir/$covrun_file")
	done
done
#bam_files=$(printf '%s\n' "${bam_files[@]}")


# replicate 2..4
# index 1..7
# get_covindex replicate index > covindex
# echo "$(get_covindex 2 1)" > 01
# echo "$(get_covindex 03 2)" > 09
get_covindex() {
	replicate=$1
	index=$2

	number=$(echo "$index+7*($replicate-2)" | bc)
	echo $(printf "%02d" $number)
}

mkdir -p $output_dir

N=4

filter_bam () {
	# more,less
	type=$1
	# regulated,wild
	modification=$2

	for replicate_id in {2..4}
	do
		for cov_id in {02..07}
		do
			((i=i%N)); ((i++==0)) && wait

			bam_covrun_id="$(get_covindex $replicate_id $([ "$modification" == "wild" ] && echo "01" || echo "$cov_id"))"
			filter_covrun_id="$(get_covindex $replicate_id $cov_id)"

			# get bam file
			#bamfile=$(printf '%s\n' "${bam_files[@]}" | grep -e "MP${bam_covrun_id}")
			if [ $arg_prefiltered = "true" ];
			then
				bamfile="$prefiltered_bam_dir/$(ls $prefiltered_bam_dir | grep "${bam_covrun_id}" | grep "sorted" | grep -v ".bai" )"
				if [[ -f $bamfile ]]
				then
					echo "using prefiltered bam file: $bamfile"
				else
					echo "prefiltered not generated: $bamfile"
					bamfile=$(printf '%s\n' "${bam_files[@]}" | grep -e "MP${bam_covrun_id}")
					echo "using original bam file: $bamfile"
				fi
			else
				bamfile=$(printf '%s\n' "${bam_files[@]}" | grep -e "MP${bam_covrun_id}")
				echo "using original bam file: $bamfile"
			fi

			# filter only for id 02..07 exists
			bedfile="${filter_dir}/regions_${type}_${cov_id}.nochr.bed"

			# save output as
			outfile="${output_dir}/${modification}_${type}_${filter_covrun_id}"

			# do not filter if file exists
			if [ -f ${outfile}.count ];
			then
				if [ $(cat ${outfile}.count) -gt 1 ]; then continue; fi
			fi

			# skip if source file does not exit
			if [ ! -f $bamfile ];
			then
				echo "-1" > $outfile.count
			fi

			# generate filtered bams
			echo "generate $outfile.bam"
			samtools view -b -o $outfile.bam -L "$bedfile" "$bamfile"
			if [ "$arg_format" = "sam" ] || [ "$arg_format" = "both" ];
			then
				echo "generate $outfile.sam"
				samtools view -h -o $outfile.sam $outfile.bam
			fi

			samtools view -c $outfile.bam > $outfile.count
			cat $outfile.count
			if [ "$arg_format" = "sam" ];
			then
				rm $outfile.bam
			fi
		done
	done
}

filter_bam "more" "regulated"
filter_bam "less" "regulated"
filter_bam "more" "wild"
filter_bam "less" "wild"
