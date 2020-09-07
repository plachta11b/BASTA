#!/bin/bash

script_directory=`dirname "$0"`; script_name=`basename "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi

prefix_in=$1 prefix_out=$2 source=${3:-reference}

if [[ $# -lt 2 ]] ; then
	echo 'not enough arguments'
	echo 'call: ./${script_name} \$prefix_in \$prefix_out [\$source=reference]'
	echo 'call: ./${script_name} default default_cut [reference|bams]'
	exit 1
fi

reference_file="$project_directory_data/reference/fasta/ensembl/Homo_sapiens.GRCh38.dna.primary_assembly.fa"
cons_dir="$project_directory_data/generate_fasta/consensus"
fasta_dir="$project_directory_data/generate_fasta/fasta/$prefix_out"
filter_dir="$project_directory_data/generate_fasta/filtered_genes/$prefix_in"

if [ ! -d "$filter_dir" ]; then echo "prefix does not exist"; ls $filter_dir/../; exit 1; fi
if [ ! -f "$reference_file" ]; then echo "reference file $reference_file does not exist"; exit 1; fi

pushd "$cons_dir"
all_cons="$(find . -type f -name "*.cons.fasta")"
popd
pushd "$filter_dir"
all_filters="$(find . -type f -name "*.nochr.bed")"
popd

# echo "$all_cons"
# echo "$all_filters"

mkdir -p "$fasta_dir"

echo "#!/bin/bash" > ${fasta_dir}/_call.sh

run() {

	replicate="$1"
	filter_file="$2"
	source="$3"

	#echo "r: $replicate f: $filter_file s: $source"

	cov_base=$(echo "$filter_file" | grep -o '[0-9][0-9]')

	# test if filename contain covariance
	if [ ! -z $cov_base ]; then
		cov=$($script_directory/../tools/get_covindex.sh $replicate $cov_base)
		fastaname=$(echo "$filter_file" | sed 's/regions_//' | sed 's/.nochr.bed/.fasta/' | sed "s/$cov_base/$cov/")
	else
		fastaname=$(echo "$filter_file" | sed 's/regions_//' | sed 's/.nochr.bed/.fasta/')
	fi

	if [ "$source" = "reference" ]; then
		sequence_in_file=$(basename $reference_file)
	else
		if [ -z $cov_base ]; then echo "no covariance specified (skip)"; return 1; fi
		sequence_in_file=$(echo "$all_cons" | grep "MP$cov")
	fi

	sequence_in_file="$(echo $sequence_in_file | sed 's/^.\///')"
	filter_file="$(echo $filter_file | sed 's/^.\///')"
	lift_file="/output/${sequence_in_file##*/}.$filter_file.lifted"

	if [ ! -z "$sequence_in_file" ]; then
		echo "sequence_in_file=$sequence_in_file" >> ${fasta_dir}/_call.sh
		echo "if [ -f \"$lift_file\" ]; then echo 'using lifted'; filter_by=\"$lift_file\"; else filter_by=\"/data/filter/$filter_file\"; fi" >> ${fasta_dir}/_call.sh
		echo "bedtools getfasta -s -name -bed \$filter_by -fi /data/cons/\$sequence_in_file -fo /output/${fastaname}.tmp" >> ${fasta_dir}/_call.sh
		echo "if [ $? -eq 0 ]; then mv \"/output/${fastaname}.tmp\" \"/output/${fastaname}\"; fi" >> ${fasta_dir}/_call.sh
		echo "cut into pieces $sequence_in_file!"
	else
		echo "reference or consensus fasta file missing: $sequence_in_file (skipping)"
	fi
}

trap "echo 'call SIGINT'; exit" INT
if [ "$source" = "reference" ]; then
	while IFS= read -r file; do run "2" "$file" "$source" </dev/null; done <<< "$all_filters"
else
	for replicate in 2 3 4; do
		while IFS= read -r file; do run "$replicate" "$file" "$source" </dev/null; done <<< "$all_filters"
	done
fi

docker_switches="--rm --tty --init"
docker_volumes="-v $(realpath $fasta_dir):/output"
docker_volumes+=" -v $(realpath $filter_dir):/data/filter"
if [ "$source" = "reference" ]; then
	docker_volumes+=" -v $(dirname $reference_file):/data/cons"
else
	docker_volumes+=" -v $(realpath $cons_dir):/data/cons"
fi
chmod +x ${fasta_dir}/_call.sh

$script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "bedtools" "/output/_call.sh" "/dev/null"
if [ $? -ne 0 ]; then echo "container returns non-zero code"; exit 1; fi
