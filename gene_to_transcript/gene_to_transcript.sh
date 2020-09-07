#!/bin/bash

script_directory=`dirname "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
project_directory_dataset="$($script_directory/../get_directory.sh dataset)"; if [ ! $? -eq 0 ]; then echo $project_directory_dataset; exit 1; fi

counts_file="$project_directory_dataset/eIF4E_2018_08/RNAseq_eIF4E_2018_08_results/samples_to_experiment_ANOVA_PCA/HEK_to_all4Es/_isoforms_counts.txt"

arg_prefix=$1

genes_dir="$project_directory_data/generate_fasta/filtered_genes/$arg_prefix"
transcripts_dir="$project_directory_data/generate_fasta/counted_transcripts"

if [ -z "$arg_prefix" ]; then
	echo "prefix missing call ./gene_to_transcript.sh prefix"
	exit 1
fi

if [ -d $genes_dir ]; then
	mkdir -p $transcripts_dir/$arg_prefix
else
	echo "gene dir does not exist (exiting)"
	exit 1
fi

docker_switches="--rm --tty --init"
output_dir=$transcripts_dir/$arg_prefix
docker_volumes="-v $(realpath $genes_dir):/data -v $(realpath $transcripts_dir):/transcripts -v $(realpath $output_dir):/output"
read -r -d '' run_script << "EOM"
	#!/bin/bash
	echo "generate transcript files.."
	for genes_file in /data/*.txt
	do
		cov="$(echo "$genes_file" | grep -E -o '_[0-9]{2}.' | grep -E -o '[0-9]{2}')"
		echo "covariant: $cov, file: $genes_file"

		rm -f ${genes_file/data/output}
		while IFS= read -r gene; do
			LC_ALL=C grep -F -m 1 "$gene" /transcripts/main_counts_$cov.txt | tee /dev/tty | grep -E -o 'ENST[0-9]*' >> ${genes_file/data/output}
		done < "${genes_file}"
	done
EOM

echo "#!/bin/bash" > ${output_dir}/call.sh
echo "arg_prefix=$arg_prefix" >> ${output_dir}/call.sh
echo "$run_script" | awk '{$1=$1;print}' >> ${output_dir}/call.sh
chmod +x ${output_dir}/call.sh
$script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "bedops" "/output/call.sh" "/dev/null"
