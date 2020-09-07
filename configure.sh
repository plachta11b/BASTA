#!/bin/bash

script_directory=`dirname "$0"`; config="$script_directory/project.config"

if [ ! -f "$config" ]; then
	$script_directory/read_config.sh init
	echo "Look into config file $config and set project paths"
	exit 1
fi

# TODO implement --force-remove flag to to restart project

# WARNING: please do not use symbolic links in project configuration (docker doesn't like that)

# valid configuration variables: MF_PROJECT_DATA_DIR, MF_PROJECT_DATASET_DIR, COMMAND_SINGULARITY, COMMAND_DOCKER
# (set config file instead if you do not know what are you doing)

project_directory_data="$($script_directory/get_directory.sh data)";
if [ ! $? -eq 0 ]; then echo "$project_directory_data"; exit 1; fi
project_directory_dataset="$($script_directory/get_directory.sh dataset)";
if [ ! $? -eq 0 ]; then echo "$project_directory_dataset"; exit 1; fi

alias_dataset_dirs="${project_directory_data}/generate_fasta/source_data"

# this is dataset specific code (MODIFY THIS)
# todo add anova file and counts file to config
echo "this configuration script contain dataset specific code!"
raw_dir="${project_directory_dataset}/eIF4E_2018_08"
bam_dir="${project_directory_dataset}/eIF4E_2018_08/RNAseq_eIF4E_2018_08_results/PKG_ Alignments_and_gene_counts_IGV_ready"
anova_dir="${project_directory_dataset}/eIF4E_2018_08/RNAseq_eIF4E_2018_08_results/samples_to_experiment_ANOVA_PCA/HEK_to_all4Es/ANOVA_like"

[[ ! -d "$raw_dir" ]] && echo "missing raw folder: $raw_dir" && exit 1
[[ ! -d "$bam_dir" ]] && echo "missing bam folder: $bam_dir" && exit 1
[[ ! -d "$anova_dir" ]] && echo "missing anova folder: $anova_dir" && exit 1

mkdir -p $alias_dataset_dirs
rm -f $alias_dataset_dirs/*

# no need to create folder bam
ln -sf "$raw_dir" $alias_dataset_dirs/raw
ln -sf "$bam_dir" $alias_dataset_dirs/bam
ln -sf "$anova_dir" $alias_dataset_dirs/anova

ls $alias_dataset_dirs/

$script_directory/pull_containers.sh

$script_directory/reference/get_annotation.sh "ebi_gencode"
$script_directory/reference/get_reference.sh "ensembl"

echo "Configuration done!"
echo "Look into config file $script_directory/project.config to configure this project"
