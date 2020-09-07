#!/bin/bash

script_directory=`dirname "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
project_directory_dataset="$($script_directory/../get_directory.sh dataset)"; if [ ! $? -eq 0 ]; then echo $project_directory_dataset; exit 1; fi

anova_file="$project_directory_dataset/eIF4E_2018_08/RNAseq_eIF4E_2018_08_results/samples_to_experiment_ANOVA_PCA/HEK_to_all4Es/ANOVA_like/ANOVAlike__counts.txt"
data_directory="$project_directory_data/generate_fasta"
reference_directory="$project_directory_data/reference"
annotation_file_ebi="ebi_gencode/gencode.v34.chr_patch_hapl_scaff.annotation.gff3"
annotation_file_ensembl="ensembl/Homo_sapiens.GRCh38.100.gff3"

arg_prefix=$1
arg_fdr=$2
arg_gene_count=$3
arg_bg_gene_count=$4
sequence_type=$5
source=$6

# TODO remove dependency on sequence region and move it to bed file preparation in other file

if [[ $# -lt 6 ]] ; then
	echo 'not enough arguments'
	echo "call: $0 \$prefix \$fdr \$gene_count \$bg_gene_count \$sequence_type \$reference_source"
	echo "example call: $0 default 0.01 50 50 gene ENSEMBL"
	echo "example call: $0 default 0.01 30 30 five_prime_UTR EBI_GENCODE"
	echo "call: $script_directory/help.sh for list of \$sequence_type available"
	echo "ENSEMBL and EBI_GENCODE annotation files are available"
	exit 1
fi

radical="false"
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	--radical) radical="true"; shift; ;;
	-h|--help) ./$script_directory/help.sh; exit 0; shift; ;;
	*) shift; ;;
esac; done

echo "./make_filter.sh prefix=$arg_prefix fdr=$arg_fdr gene-count=$arg_gene_count bg-gene-count=$arg_bg_gene_count sequence_type=$sequence_type"

annotation_file="$annotation_file_ebi"
if [ "$source" = "ENSEMBL" ]; then
	annotation_file="$annotation_file_ensembl"
fi

annotation_dir="$reference_directory/annotation"
output_dir="$data_directory/filtered_genes/$arg_prefix"

# test if source data available
if [ ! -n "$(ls -A $anova_dir)" ]; then echo "anova_dir missing"; exit; fi
if [ ! -n "$(ls -A $annotation_dir)" ]; then echo "annotation_dir missing"; exit; fi

mkdir -p $output_dir

limit_FDR=$arg_fdr
limit_gene_count=$arg_gene_count

function skip_first_n {

	if [ ! -t 0 ]; then INPUT="$(cat)"; else INPUT=""; fi

	echo "$INPUT" | awk '{if (NR>n) print}' n=$1
}

function skip_last_n {

	if [ ! -t 0 ]; then INPUT="$(cat)"; else INPUT=""; fi

	# Scrutinizer: https://askubuntu.com/a/475720
	echo "$INPUT" | awk 'NR>n{print A[NR%n]} {A[NR%n]=$0}' n=$1
}

function get_tag {
	# parse ENSG tag from whole line in ANOVAlike__counts.txt

	if [ ! -t 0 ]; then INPUT="$(cat)"; else INPUT=""; fi

	echo "$INPUT" | awk '{ print $1 }' |  sed 's/\"//g' | awk -F ':' '{print $2}'
}

echo "generate region files..."
for collumn in {2..7}
do
	collumn_prefixed=$(printf "%02d" $collumn)
	filtered_fdr_file=$script_directory/filtered_fdr_file_tmp
	echo "process: $collumn_prefixed"
	cat "$anova_file" | sed 1d | awk '{ if ($11 < '$limit_FDR') { print } }' | LC_ALL=en_US sort -r -g -k $collumn,$collumn > $filtered_fdr_file
	echo "filtered fdr file done"

	if [ "$radical" = "true" ]; then
		cat $filtered_fdr_file | head -n $limit_gene_count | get_tag > ${output_dir}/regions_primary_radical_${collumn_prefixed}.txt &
		cat $filtered_fdr_file | tail -n $limit_gene_count | get_tag | tac > ${output_dir}/regions_background_radical_${collumn_prefixed}.txt &
	else
		cat $filtered_fdr_file | head -n $limit_gene_count | get_tag > ${output_dir}/regions_primary_more_${collumn_prefixed}.txt &
		cat $filtered_fdr_file | skip_first_n $limit_gene_count | get_tag | shuf -n $arg_bg_gene_count > ${output_dir}/regions_background_more_${collumn_prefixed}.txt &
		cat $filtered_fdr_file | tail -n $limit_gene_count | get_tag | tac > ${output_dir}/regions_primary_less_${collumn_prefixed}.txt &
		cat $filtered_fdr_file | skip_last_n $limit_gene_count | get_tag | tac | shuf -n $arg_bg_gene_count > ${output_dir}/regions_background_less_${collumn_prefixed}.txt &
	fi

	# todo min file shuffle and cut n genes as background

	echo "wait for all regions file"
	wait
	rm $filtered_fdr_file

	echo "end"
done

if [ "$sequence_type" = "none" ]; then
	echo "done"
	exit 0
fi

echo "generate raw annotation filter.."
small_annotation_file="${annotation_dir}/${annotation_file%.*}.${sequence_type}.gff3"

if [ ! -f ${small_annotation_file}  ]; then
	# filter by sequence_type
	cat ${annotation_dir}/${annotation_file} | LC_ALL=C grep -F -w "${sequence_type}" > ${small_annotation_file}
fi

# TODO move this to other file as it is not needed for biomart
docker_switches="--rm --tty --init"
docker_volumes="-v $(realpath $output_dir):/data -v $(dirname $small_annotation_file):/annotation"
read -r -d '' gff2bed_script << "EOM"
	#!/bin/bash
	echo "generate bed files.."
	for genes_file in /data/*.txt
	do
		filename_whole=$(basename ${genes_file})
		echo "generate bed from: ${filename_whole}"
		filename="${filename_whole%%.*}"
		outfile=/data/${filename}.nochr.bed
		if [ -f ${outfile} ]; then continue; fi

		echo "filter genes"
		cat /annotation/${small_annotation_file} | LC_ALL=C grep -F -f ${genes_file} > /data/${filename}.gff3

		echo "convert gff3 to bed"
		cat /data/${filename}.gff3 | gff2bed > /data/${filename}.bed

		echo "filter chr from bed file"
		cat /data/${filename}.bed | sed 's/^chr//' > $outfile.part
		mv $outfile.part $outfile
	done
EOM

echo "$gff2bed_script" | awk '{$1=$1;print}' | sed "s/\${small_annotation_file}/$(basename $small_annotation_file)/" > ${output_dir}/call.sh
chmod +x ${output_dir}/call.sh
$script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "bedops" "/data/call.sh" "/dev/null"

echo "done"
