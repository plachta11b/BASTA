#!/bin/bash

script_directory=`dirname "$0"`

project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
reference_dir="${project_directory_data}/reference/fasta"

source_organization="$1"

if [[ "$source_organization" = *"ucsc"* ]]; then
	# https://hgdownload.soe.ucsc.edu/downloads.html#human
	mkdir -p $reference_dir/ucsc
	file_ucsc="$reference_dir/ucsc/hg38.fa.gz"
	if [ ! -f $file_ucsc ] && [ ! -f ${file_ucsc%.gz} ]; then
		curl "http://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz" > "$file_ucsc"

		if [[ "$(sha1sum $file_ucsc)" != *"8e8ae3f73d61c3ec8c2477334199557128946276"* ]]; then
			echo "ucsc: sha does not match (removing)"
			rm "$file_ucsc"
		else
			echo "file integrity OK"
		fi
	else
		echo "ucsc reference file already exists!"
	fi
	if [ -f $file_ucsc ] && [ ! -f ${file_ucsc%.gz} ]; then
			echo "gzip -d $file_ucsc"
			gzip -d "$file_ucsc"
	fi
elif [[ "$source_organization" = *"ensembl"* ]]; then
	# http://www.ensembl.org/Homo_sapiens/Info/Index
	mkdir -p $reference_dir/ensembl
	file_ensembl="$reference_dir/ensembl/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
	if [ ! -f $file_ensembl ] && [ ! -f ${file_ensembl%.gz} ]; then
		curl "ftp://ftp.ensembl.org/pub/release-100/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz" > "$file_ensembl"

		if [[ "$(sha1sum $file_ensembl)" != *"1c5aab59b9d971cffcc028e4055d985c648b8488"* ]]; then
			echo "ensembl: sha does not match (removing)"
			rm "$file_ensembl"
		else
			echo "file integrity OK"
		fi
	else
		echo "ensembl reference file already exists!"
	fi
	if [ -f $file_ensembl ] && [ ! -f ${file_ensembl%.gz} ]; then
			echo "gzip -d $file_ensembl"
			gzip -d "$file_ensembl"
	fi
elif [[ "$source_organization" = *"ebi_gencode"* ]]; then
	# https://www.gencodegenes.org/human/
	mkdir -p $reference_dir/ebi_gencode
	file_ebi_gencode="$reference_dir/ebi_gencode/GRCh38.p13.genome.fa.gz"
	if [ ! -f $file_ebi_gencode ] && [ ! -f ${file_ebi_gencode%.gz} ]; then
		curl "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_34/GRCh38.p13.genome.fa.gz" > "$file_ebi_gencode"

		if [[ "$(sha1sum $file_ebi_gencode)" != *"ca209a8ad419fb6a89018dc1b6e1f03423ea2569"* ]]; then
			echo "ebi_gencode: sha does not match (removing)"
			rm "$file_ebi_gencode"
		else
			echo "file integrity OK"
		fi
	else
		echo "ebi_gencode reference file already exists!"
	fi
	if [ -f $file_ebi_gencode ] && [ ! -f ${file_ebi_gencode%.gz} ]; then
			echo "gzip -d $file_ebi_gencode"
			gzip -d "$file_ebi_gencode"
	fi
else
	echo "specify source ./get_reference.sh ucsc|ensembl|ebi_gencode"
fi

echo "get_reference.sh done!"
