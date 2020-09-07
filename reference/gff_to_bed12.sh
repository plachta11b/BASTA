#!/bin/bash

script_directory=`dirname "$0"`

project_directory_data="$($script_directory/../get_directory.sh data)"; if [ ! $? -eq 0 ]; then echo $project_directory_data; exit 1; fi
annotation_dir="${project_directory_data}/reference/annotation/ebi_gencode"
output_dir="$annotation_dir/agar_temp"

annotation_file="$(find $annotation_dir -name gencode.*.annotation.gff3 -maxdepth 1 -type f)"; annotation_file="${annotation_file##*/}"

echo "only ebi_gencode supported now!"

if [ -z "$annotation_file" ]; then
	echo "no annotation file found!"
	exit 1
else
	echo "using annotation file: $annotation_file"
fi

mkdir -p $output_dir
mkdir -p $annotation_dir

##
## Those tools are known as gff to bed convertors
##
## must read (tools review) https://github.com/NBISweden/GAAS/blob/master/annotation/knowledge/gff_to_bed.md
## gencode_regions https://github.com/saketkc/gencode_regions
## gfftoolsgx
## eagenomics/ea-utils gtf2bed

##
## Using Agat is too memory intensive (8 Killed) DO NOT USE THIS
##

# docker_switches="--rm --tty --init"
# docker_volumes="-v $(realpath $output_dir):/data -v $(realpath $annotation_dir):/annotation"
# read -r -d '' agat_script << "EOM"
# 	agat_convert_sp_gff2bed.pl --gff /annotation/${filename}.gff3 -o /annotation/${filename}.bed
# EOM

# echo "#!/bin/bash" > ${output_dir}/call.sh
# echo "filename=${annotation_file%.gff3}" >> ${output_dir}/call.sh
# echo "$agat_script" | awk '{$1=$1;print}' >> ${output_dir}/call.sh
# chmod +x ${output_dir}/call.sh
# $script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "agat" "/data/call.sh" "/dev/null"

##
## GFFtools-GX -> this one prints only CDS not UTR :(
##

# docker_switches="--rm --tty --init"
# docker_volumes="-v $(realpath $output_dir):/data -v $(realpath $annotation_dir):/annotation"
# read -r -d '' conversion_script << "EOM"
# 	python /GFFtools-GX/gff_to_bed.py /annotation/${filename}.gff3 > /annotation/${filename}.bed
# EOM

# echo "#!/bin/bash" > ${output_dir}/call.sh
# echo "filename=${annotation_file%.gff3}" >> ${output_dir}/call.sh
# echo "$conversion_script" | awk '{$1=$1;print}' >> ${output_dir}/call.sh
# chmod +x ${output_dir}/call.sh
# $script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "gfftoolsgx" "/data/call.sh" "/dev/null"

##
## gencode_regions can generate only BED6
##

# docker_switches="--rm --tty --init"
# docker_volumes="-v $(realpath $output_dir):/data -v $(realpath $annotation_dir):/annotation"
# read -r -d '' conversion_script << "EOM"
# 	/gencode_regions/create_regions_from_gencode.R /annotation/${filename}.gff3 /annotation/regions
# EOM

# echo "#!/bin/bash" > ${output_dir}/call.sh
# echo "filename=${annotation_file%.gff3}" >> ${output_dir}/call.sh
# echo "$conversion_script" | awk '{$1=$1;print}' >> ${output_dir}/call.sh
# chmod +x ${output_dir}/call.sh
# $script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "gencode_regions" "/data/call.sh" "/dev/null"

##
## ucsc gff3ToGenePred and genePredToBed used in this container
##

docker_switches="--rm --tty --init"
docker_volumes="-v $(realpath $output_dir):/data -v $(realpath $annotation_dir):/annotation"
read -r -d '' conversion_script << "EOM"
	gff2bed /annotation/${filename}.gff3 /annotation/${filename}.bed

	# cat /annotation/${filename}.gff3 | LC_ALL=C grep -F -w "gene" > /data/${filename}.gene.gff3
	# cat /annotation/${filename}.gff3 | LC_ALL=C grep -F -w "transcript" > /data/${filename}.transcript.gff3
	# cat /annotation/${filename}.gff3 | LC_ALL=C grep -F -w "five_prime_UTR" > /data/${filename}.five_prime_UTR.gff3
	# cat /annotation/${filename}.gff3 | LC_ALL=C grep -F -w "three_prime_UTR" > /data/${filename}.three_prime_UTR.gff3

	# filter in gene/transcript/UTR5
	# cat /annotation/${filename}.gff3 | LC_ALL=C grep "gene\|transcript\|five_prime_UTR\|^#" > /data/${filename}.five_prime_UTR.complete.gff3
	# gff2bed /data/${filename}.five_prime_UTR.complete.gff3 /data/${filename}.five_prime_UTR.bed

	# filter in gene/transcript/CDS
	#cat /data/${filename}.gene.gff3 /data/${filename}.transcript.gff3 /data/${filename}.CDS.gff3 > /data/${filename}.CDS.complete.gff3
	# filter in gene/transcript/UTR3
	#cat /data/${filename}.gene.gff3 /data/${filename}.transcript.gff3 /data/${filename}.three_prime_UTR.gff3 > /data/${filename}.three_prime_UTR.complete.gff3
	echo "done!"
EOM

echo "#!/bin/bash" > ${output_dir}/call.sh
echo "filename=${annotation_file%.gff3}" >> ${output_dir}/call.sh
echo "$conversion_script" | awk '{$1=$1;print}' >> ${output_dir}/call.sh
chmod +x ${output_dir}/call.sh
$script_directory/../run_daemon.sh "$docker_switches" "" "$docker_volumes" "ucsc_gff2bed" "/data/call.sh" "/dev/null"
