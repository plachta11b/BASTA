#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`

project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
data_directory="${project_directory_data}/generate_fasta"

# get variables
arg_prefix=$1
threads=1 # number of threads
reference=$data_directory/reference/GRCh38_p13/genome.fa

if [[ $# -lt 1 ]] ; then
	echo "not enough arguments"
	echo "call: ./${script_name} \$prefix"
	echo "example call: ./${script_name} default"
	exit 1
fi

# gzcat "/Users/plachta/bioproject/generate_fasta/source_data/raw/PKG - Pospisek_HLF2VBGX7/HLF2VBGX7_MP01_18s004051-1-1_Pospisek_lane118s004051_sequence.txt.gz" | docker run biocontainers/seqtk:v1.3-1-deb_cv1 seqtk seq | docker run -i -v /Users/plachta/bioproject/generate_fasta/reference/GRCh38_p13:/ref_dir quay.io/biocontainers/bwa:0.7.17--hed695b0_7 bwa mem -v 4 -t 1 /ref_dir/genome.fa /dev/stdin > test

#out_bam_filename="${reads//\.*/}.on.${reference//\.fasta}.bam"

in="$data_directory/source_data/raw"
out="$data_directory/alignment/result/$arg_prefix"
mkdir -p $out

echo "create containers"
#con_bwa=$($script_directory/get_container.sh $(dirname $reference) $(realpath "./") $out | grep 'bwa')
con_bwa=$($script_directory/get_container.sh $(dirname $reference) $in $out | grep 'bwa')
con_samtools=$($script_directory/get_container.sh $(dirname $reference) $in $out | grep 'samtools')

get_alignment() {

	reference_short=$1
	reads_short=$2
	out_bam_filename=$(echo $(basename $2) | awk -F'_' '{print $2}')

	# index reference file
	if [ ! -f $reference.pac ];
	then
		echo "index reference file"
		#$con_bwa index /ref_dir/${reference}
		echo "indexed"
	fi

	echo "input bwa"
	echo $reference_short
	echo $reads_short
	echo $con_bwa

	echo "/ref_dir/${reference_short}"
	echo "/data_dir/${reads_short}"

	# create bam files
	$con_bwa mem -t ${threads} "/ref_dir/${reference_short}" "/data_dir/${reads_short}" | tee bwa_mem_file | $con_samtools view -F 4 -b - | $con_samtools sort - | tee $out/${out_bam_filename} | wc -l
	#$con_samtools index /output/${out_bam_filename}
}

reps='PKG - Pospisek_HLF2VBGX7\nPKG - Pospisek_HVGWYBGX7\nPKG - Pospisek_HVH5TBGX7'
while IFS= read -r reads_rep; do
	while IFS= read -r rr; do
		echo $rr
		get_alignment $(basename $reference) "$reads_rep/$rr"
	done <<< "$(ls "$in/$reads_rep/" | grep .txt.gz)"
done <<< "$(echo -e $reps)"
