#!/bin/bash

script_directory=`dirname "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
project_directory_dataset="$($script_directory/../get_directory.sh dataset)"; if [ ! $? -eq 0 ]; then echo $project_directory_dataset; exit 1; fi

counts_file="$project_directory_dataset/eIF4E_2018_08/RNAseq_eIF4E_2018_08_results/samples_to_experiment_ANOVA_PCA/HEK_to_all4Es/_isoforms_counts.txt"

transcripts_dir="$project_directory_data/generate_fasta/counted_transcripts"

if [ -d $genes_dir ]; then
	mkdir -p $transcripts_dir
else
	echo "gene dir does not exist (exiting)"
	exit 1
fi

annotation_dir="$project_directory_data/reference/annotation/ebi_gencode"
annotation_file="$(find $annotation_dir -maxdepth 1 -name gencode.*.annotation.gff3 -type f)"; annotation_file="${annotation_file##*/}"

if [ ! -f $transcripts_dir/transcripts.noversion.txt ]; then
	cat ${annotation_dir}/${annotation_file} | LC_ALL=C grep -F -w "transcript" | sed 's/.*ID=\([^;^\.]*\).*gene_id=\([^;^\.]*\).*/\1 \2/' > $transcripts_dir/transcripts.noversion.txt
	# cat ${annotation_dir}/${annotation_file} | LC_ALL=C grep -F -w "transcript" | sed 's/.*ID=\([^;]*\).*gene_id=\([^;]*\).*/\1 \2/' > transcripts.txt
else
	echo "already filtered: $transcripts_dir/transcripts.noversion.txt"
fi

if [ ! -f $transcripts_dir/transcripts.noversion.sorted.txt ]; then
	LC_ALL=C sort -k1 $transcripts_dir/transcripts.noversion.txt > $transcripts_dir/transcripts.noversion.sorted.txt
	# LC_ALL=C sort -k1 transcripts.txt > transcripts.sorted.txt
else
	echo "already sorted: $transcripts_dir/transcripts.noversion.sorted.txt"
fi

if [ ! -f $transcripts_dir/main_counts.txt ]; then
	echo "" > $transcripts_dir/main_counts.txt
	first=true
	while IFS= read -r line; do
		# skip header
		if [ $first = "true" ]; then
			first=false
			continue
		fi

		transcript="$(echo "$line" | cut -f 1)"
		gene="$(LC_ALL=C look "${transcript}" $transcripts_dir/transcripts.noversion.sorted.txt | cut -d " " -f 2 | head -n 1)"

		# outdated transcript
		if [ -z "$transcript" ]; then echo "invalid line: $line"; continue; fi
		if [ -z "$gene" ]; then gene="no_valid_gene"; fi

		echo "$transcript $gene $(echo "$line" | cut -f2-)" | sed $'s/ /\t/g' >> $transcripts_dir/main_counts.txt
	done < "$counts_file"
else
	echo "counts already converted: $transcripts_dir/main_counts.txt"
fi


column=3
for i in {1..21}; do
	LC_ALL=C sort -k$column --numeric-sort -r $transcripts_dir/main_counts.txt > "$transcripts_dir/main_counts_$(printf "%02d" $i).txt"
	column=`expr ${column} + 1`
done
