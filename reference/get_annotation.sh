#!/bin/bash

script_directory=`dirname "$0"`

project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
reference_dir="${project_directory_data}/reference/annotation"

source_organization="$1"

gffreadcontainer="$($script_directory/../run_daemon.sh "-i" "" "" "gffread" "gffread -E - -o-" "return_no_run" | grep "run_command" | sed 's/run_command: //')"
gffreadcontainer_version="$($script_directory/../run_daemon.sh "-i" "" "" "gffread" "gffread --help" "return_no_run" | grep "run_command" | sed 's/run_command: //')"

# https://hgdownload.soe.ucsc.edu/downloads.html#human
# https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/genes/

if [[ "$source_organization" == *"ucsc"* ]]; then
	# gffread version check to test if container available
	if [[ "$($gffreadcontainer_version 2>&1 >/dev/null | head -n 1)" == *"gffread v0.11.7. Usage:"* ]]; then
		mkdir -p $reference_dir/ucsc

		files="ensGene knownGene ncbiRefSeq refGene"
		database="https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/genes"

		for file in $files; do
			echo "$reference_dir/ucsc/$file.gff3"
			if [ ! -f "$reference_dir/ucsc/$file.gff3" ]; then
				echo "downloading $database/hg38.$file.gtf.gz"
				curl -s -N "$database/hg38.$file.gtf.gz" | gzip -d | $gffreadcontainer 2>/dev/null > $reference_dir/ucsc/$file.gff3
				echo "done $reference_dir/ucsc/$file.gff3"
			else
				echo "ucsc annotation file already exists: $reference_dir/ucsc/$file.gff3"
			fi
		done
	else
		echo "gff read container not available"
	fi

elif [[ "$source_organization" = *"ensembl"* ]]; then
	# ftp://ftp.ensembl.org/pub/release-100/gff3/homo_sapiens/
	mkdir -p $reference_dir/ensembl
	if [ ! -f $reference_dir/ensembl/Homo_sapiens.GRCh38.100.gff3 ]; then
		curl -s -N "ftp://ftp.ensembl.org/pub/release-100/gff3/homo_sapiens/Homo_sapiens.GRCh38.100.gff3.gz" | gzip -d > $reference_dir/ensembl/Homo_sapiens.GRCh38.100.gff3
	else
		echo "ensembl annotation file already exists!"
	fi
elif [[ "$source_organization" = *"ebi_gencode"* ]]; then
	# https://www.gencodegenes.org/human/
	mkdir -p $reference_dir/ebi_gencode
	if [ ! -f $reference_dir/ebi_gencode/gencode.v34.chr_patch_hapl_scaff.annotation.gff3 ]; then
		curl -s -N "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_34/gencode.v34.chr_patch_hapl_scaff.annotation.gff3.gz" | gzip -d > $reference_dir/ebi_gencode/gencode.v34.chr_patch_hapl_scaff.annotation.gff3
	else
		echo "ebi_gencode annotation file already exists!"
	fi
else
	echo "specify source ./get_annotation.sh ucsc|ensembl|ebi_gencode"
fi

echo "get_annotation.sh done!"
