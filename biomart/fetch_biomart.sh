#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

data_directory="$project_directory_data/generate_fasta"

prefix=$1
gene_type=$2

if [[ $# -lt 2 ]]; then
    echo 'not enough arguments'
    echo 'call: ./${script_name} \$prefix \$gene_type'
    echo 'example: ./${script_name} default cdna'
    echo 'example: ./${script_name} default gene_exon'
	echo 'gene_type: 5utr 3utr gene_exon cdna coding'
	echo 'for transcript use option: -t, --transcripts'
    exit 1
fi

transcript="false"
new_prefix="$prefix"
while [[ $# -gt 0 ]]; do key="$1"; value="$2"; case ${key} in
	-r|--rename) new_prefix="$2"; shift; shift; ;;
	-t|--transcript|--transcripts) transcript="true"; shift; ;;
	-f|--force) echo "not implemented yet!"; shift; ;;
	*) shift; ;;
esac; done

trap 'echo oh, I am slain; exit' INT

out_dir=$data_directory/fasta/$new_prefix
mkdir -p $out_dir

# filter by one of these: ensembl_gene_id, ensembl_gene_id_version, ensembl_transcript_id, ensembl_transcript_id_version
if [ "$transcript" = "true" ]; then
	FILTER_NAME="ensembl_transcript_id"
	regions_dir="$data_directory/counted_transcripts/$prefix"
else
	FILTER_NAME="ensembl_gene_id"
	regions_dir="$data_directory/filtered_genes/$prefix"
fi

if [ ! -d $regions_dir ]; then echo "no genes data: $regions_dir"; exit 1; fi

echo "#!/bin/bash" > ${out_dir}/_call_biomart.sh
for run in $regions_dir/*.txt
do
	# check gene region name
	if [[ ${run##*/} != *"_"*"_"* ]]; then continue; fi

	run_filename=$(basename $run)
	echo "fetch $run_filename"

	FILTER_VALUE="$(cat $run | paste -s -d "," -)"
	GENE_TYPE=$gene_type

	outfile_fasta=$(echo "${run_filename/.txt/.fasta}" | sed -e "s/regions_//")
	outfile_query=${outfile_fasta/.fasta/.query.xml}

	cat $script_directory/query.xml | sed -e "s/\${FILTER_NAME}/$FILTER_NAME/" | sed -e "s/\${FILTER_VALUE}/$FILTER_VALUE/" | sed -e "s/\${GENE_TYPE}/$GENE_TYPE/" > ${out_dir}/${outfile_query}

	if [ -f $out_dir/$outfile_fasta ];
	then
		echo "file for $run_filename already exists (skipping)"
		continue
	fi

	echo "echo \"download ${outfile_query}\"" >> ${out_dir}/_call_biomart.sh
	echo "perl /biomart-perl/scripts/webExample.pl /output/${outfile_query} > /output/${outfile_fasta}.tmp" >> ${out_dir}/_call_biomart.sh
	echo "if [ $? -eq 0 ]; then mv /output/${outfile_fasta}.tmp /output/${outfile_fasta}; else echo \"filter short error\"; exit 1; fi" >> ${out_dir}/_call_biomart.sh
	echo "[ -s /output/$outfile_fasta ] || echo \"error: file is empty (removing)\" || rm /output/$outfile_fasta" >> ${out_dir}/_call_biomart.sh
done

docker_switches="--rm --init --entrypoint /bin/bash"
docker_volumes="-v $(realpath $out_dir):/output"
chmod +x ${out_dir}/_call_biomart.sh
$script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "biomart" "/output/_call_biomart.sh" "/dev/null"

echo "#!/bin/bash" > ${out_dir}/_call_fix.sh
for run in $out_dir/*.fasta
do

	# check fasta filename (have to contain two underscores)
	if [[ ${run##*/} != *"_"*"_"* ]]; then continue; fi

	status_file=${run%.*}.info

	echo "fix file: $run"

	echo "${script_name} $new_prefix $gene_type" >> $status_file

	if ! grep -q "empty_sequence_removed" "$status_file"; then
		# sometime sequence missing in biomart
		$script_directory/fix_no_data_error.sh $run
		echo "empty_sequence_removed" >> $status_file
	else
		echo "empty_sequence_removed already done"
	fi

	if ! grep -q "duplicate_header_fixed" "$status_file"; then
		# remove duplicate headers
		cat $run | $script_directory/fix_duplicate_header.awk > $run.temp
		cat $run.temp | tac | tail -n +2 | tac > $run.temp2
		mv $run.temp2 $run
		echo "duplicate_header_fixed" >> $status_file
	else
		echo "duplicate_header_fixed already done"
	fi

	if ! grep -q "short_sequence_removed" "$status_file"; then
		file=$(basename $run)
		echo "cat /output/${file} | seqtk seq -L 8 - > /output/${file}.temp" >> ${out_dir}/_call_fix.sh
		echo "if [ \$? -eq 0 ]; then mv /output/${file}.temp /output/${file}; else echo \"filter short error\"; exit 1; fi" >> ${out_dir}/_call_fix.sh
		echo "echo \"short_sequence_removed\" >> /output/$(basename ${status_file})" >> ${out_dir}/_call_fix.sh
	else
		echo "short_sequence_removed already done"
	fi
done

docker_switches="--rm --init"
docker_volumes="-v $(realpath $out_dir):/output"
chmod +x ${out_dir}/_call_fix.sh
$script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "seqtk" "/output/_call_fix.sh" "/dev/null"

# TODO create fasta file list

# query files are great for debugging but thez can be removed in production

echo "done!"
