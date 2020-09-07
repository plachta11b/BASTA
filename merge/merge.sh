script_directory=`dirname "$0"`
project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
out_dir="$project_directory_data/generate_fasta/fasta"

prefix=$1
prefix_biomart="${prefix}_biomart"

echo $prefix

if [ ! -d $out_dir/$prefix_biomart ]; then
	echo "no biomart data for: $prefix_biomart"
	# ls $out_dir
	exit 1
fi

# primary_more_02.fasta, primary_less_02.fasta => primary_02.fasta background_02.fasta
for file in $out_dir/$prefix_biomart/*; do
	file="$(grep '.fasta$' <<< $file)"
	if [[ "$file" != *"primary_more"* ]]; then continue; fi
	primary="$(realpath $file)"
	background="$(sed 's/primary_more/primary_less/' <<< $(realpath $file))"
	new_primary="$(echo "$primary" | sed 's/dataset_balance/dataset_balance_radical/' | sed 's/primary_more/primary_radical/')"
	new_background="$(echo "$background" | sed 's/dataset_balance/dataset_balance_radical/' | sed 's/primary_less/background_radical/')"
	mkdir -p $(dirname $new_primary)
	echo "$primary -> $new_primary"
	echo "$background -> $new_background"
	cp $primary $new_primary
	cp $background $new_background
done




