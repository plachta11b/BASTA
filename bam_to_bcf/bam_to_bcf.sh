#!/bin/bash

script_directory=`dirname "$0"`
project_directory_dataset="$($script_directory/../get_directory.sh dataset)"; if [ ! $? -eq 0 ]; then echo $project_directory_dataset; exit 1; fi
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

data_bam_dir="$project_directory_dataset/eIF4E_2018_08/RNAseq_eIF4E_2018_08_results/PKG_ Alignments_and_gene_counts_IGV_ready"
reference="$project_directory_data/reference/fasta/ensembl/Homo_sapiens.GRCh38.dna.primary_assembly.fa"
output="$project_directory_data/generate_fasta/bcf"
all_bams="$(find "$data_bam_dir" -type f -name "*.bam")"

mkdir -p "$output"

#bcftools mpileup -Ou -f reference alignment.bam | bcftools call -Ou -mv > alignment.ref.bcf

ln -sf "$data_bam_dir" $output/bam_in

run() {
	bam="$1"

	bam_dir="${bam%/*}"; bam_file="${bam##*/}"
	ref_dir="${reference%/*}"; ref_file="${reference##*/}"

	filename="$(echo "${bam##*/}" | sed -n -e 's/^.*\(_MP[0-9]*_\).*/\1/p' | sed 's/_//g')"
	sub_output="${output}/${filename}_part"

	if [ -d ${output}/${filename} ]; then echo "folder ${filename} already exist (skip)"; return 0; fi

	mkdir -p "$sub_output"

	docker_switches="--rm --tty"
	docker_volumes="-v $output/bam_in:/data/bam -v $ref_dir:/data/ref -v $sub_output:/output/"

	docker_execute="bcftools mpileup -Ou -f /data/ref/$ref_file /data/bam/$bam_file | bcftools call --output-type u -mv --output /output/$filename.ref.bcf"
	echo "#!/bin/bash" > $sub_output/call.sh
	echo "$docker_execute" >> $sub_output/call.sh
	chmod +x $sub_output/call.sh

	$script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "bcftools" "/output/call.sh" "${sub_output}/stdout.log"

	if [ $? -eq 0 ]; then
		mv "$sub_output" "${output}/${filename}"
	fi
}

trap "echo 'call SIGINT'; exit" INT
while IFS= read -r file; do run "$file" </dev/null; done <<< "$all_bams"

rm -r $output/bam_in
