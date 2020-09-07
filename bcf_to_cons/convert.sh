#!/bin/bash

script_directory=`dirname "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

reference="$project_directory_data/reference/fasta/ensembl/Homo_sapiens.GRCh38.dna.primary_assembly.fa"
data_bcf_dir="$project_directory_data/generate_fasta/bcf"
data_cons_dir="$project_directory_data/generate_fasta/consensus"
all_bcf="$(find "$data_bcf_dir" -type f -name "*.ref.bcf")"

mkdir -p "$data_cons_dir"

# https://samtools.github.io/bcftools/howtos/consensus-sequence.html

# bcftools index calls.vcf.gz

# filter
# bcftools filter -s LowQual -i 'QUAL>30 && DP>7 && DP<100' -Ou

# normalize indels
# bcftools norm -f reference.fa calls.vcf.gz -Ob -o calls.norm.bcf

# filter adjacent indels within 5bp
# bcftools filter --IndelGap 5 calls.norm.bcf -Ob -o calls.norm.flt-indels.bcf
# bcftools index calls.norm.flt-indels.bcf

# cat reference.fa | bcftools consensus calls.norm.flt-indels.bcf > consensus.fa

run() {
	bcf="$1"

	echo $bcf

	bcf_dir="${bcf%/*}"; bcf_file="${bcf##*/}"
	ref_dir="${reference%/*}"; ref_file="${reference##*/}"

	output=${bcf_dir/generate_fasta\/bcf/generate_fasta\/consensus}
	output_tmp="${output}_part"

	if [ -d ${output} ]; then echo "folder ${output} already exist (skip)"; return 0; fi

	mkdir -p "$output_tmp"

	docker_switches="--rm --tty --init"
	docker_volumes="-v $bcf_dir:/data/bcf -v $ref_dir:/data/ref -v $output_tmp:/output/"

	echo "#!/bin/bash" > $output_tmp/call.sh
	echo "bcftools --version" >> $output_tmp/call.sh
	echo "bcftools index /data/bcf/$bcf_file" >> $output_tmp/call.sh
	echo "bcftools filter -s LowQual -i 'QUAL>30 && DP>7 && DP<100' /data/bcf/$bcf_file -Ou -o /data/bcf/${bcf_file/.bcf/filtered.bcf}" >> $output_tmp/call.sh
	echo "bcftools index /data/bcf/${bcf_file/.bcf/filtered.bcf}" >> $output_tmp/call.sh
	echo "bcftools norm -f /data/ref/$ref_file /data/bcf/${bcf_file/.bcf/filtered.bcf} -Ob -o /data/bcf/${bcf_file/.bcf/filtered.normalized.bcf}" >> $output_tmp/call.sh
	echo "bcftools filter --IndelGap 5 /data/bcf/${bcf_file/.bcf/filtered.normalized.bcf} -Ob -o /data/bcf/${bcf_file/.bcf/filtered.normundels.bcf}" >> $output_tmp/call.sh
	echo "bcftools index /data/bcf/${bcf_file/.bcf/filtered.normundels.bcf}" >> $output_tmp/call.sh
	echo "cat /data/ref/$ref_file | bcftools consensus /data/bcf/${bcf_file/.bcf/filtered.normundels.bcf} --chain /output/${bcf_file/.bcf/.cons.chain} --output /output/${bcf_file/.bcf/.cons.fasta}" >> $output_tmp/call.sh
	chmod +x $output_tmp/call.sh

	$script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "bcftools" "/output/call.sh" "${output_tmp}/stdout.log"

	if [ $? -eq 0 ]; then
		mv "$output_tmp" "$output"
	fi
}

trap "echo 'call SIGINT'; exit" INT
while IFS= read -r file; do run "$file" </dev/null; done <<< "$all_bcf"
