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

#/Users/plachta/bioproject/generate_fasta/source_data/raw/RNAseq_eIF4E_2018_08_results/PKG_\ Alignments_and_gene_counts_IGV_ready/HVH5TBGX7_MP13_18s004063-1-1_Pospisek_lane118s004063_Aligned.sortedByCoord.out.bam
in="$data_directory/source_data/prepared/eIF4E_2018_08/bams"
out="$data_directory/bam_to_fasta/result/$arg_prefix"
mkdir -p $out

echo "prepare containers"
con_vcfutils=$($script_directory/get_container.sh $(dirname $reference) $in $out | grep 'vcfutils')
con_seqtk=$($script_directory/get_container.sh $(dirname $reference) $in $out | grep 'seqtk')
con_bcftools=$($script_directory/get_container.sh $(dirname $reference) $in $out | grep 'bcftools')
con_samtools=$($script_directory/get_container.sh $(dirname $reference) $in $out | grep 'samtools')

echo $($script_directory/get_container.sh $(dirname $reference) $in $out | grep 'debug:')

echo $con_samtools

echo "run pipeline"

cat $data_directory/source_data/prepared/eIF4E_2018_08/bams/sortbycoord_MP02.bam | $con_bcftools mpileup --no-reference -Oz - | $con_bcftools consensus --missing ? --iupac-codes /dev/stdin

# cat $data_directory/source_data/prepared/eIF4E_2018_08/bams/sortbycoord_MP02.bam | $con_bcftools view /dev/stdin | sed  -e 's/SN:\([0-9XY]*\)/SN:chr\1/' -e 's/SN:MT/SN:chrM/' | $con_bcftools mpileup --fasta-ref /ref_dir/$(basename $reference) /dev/stdin

#| $con_samtools mpileup -uf /ref_dir/$(basename $reference) /dev/stdin > result.txt
#$con_bcftools mpileup -uf /ref_dir/$(basename $reference) /data_dir/sortbycoord_MP02.bam | $con_bcftools view -cg - | $con_vcfutils vcf2fq | $con_seqtk seq -A -l 70 - | sed -r "s/(>)(.*)/\1$bam.conensus/g" > $bam.consensus.fasta
