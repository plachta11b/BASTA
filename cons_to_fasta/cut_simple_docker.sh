#!/bin/bash

consensus_file=$1
bed_file=$2

volumes="-v `dirname "$consensus_file"`:/consensus/ -v $(realpath $bed_file):/regions.bed"
user="-u $(id -u ${USER}):$(id -g ${USER})"

bedtools_container="docker run -i --init --rm $user $volumes biocontainers/bedtools:v2.28.0_cv2"

$bedtools_container bedtools getfasta -s -bed /regions.bed -fi /consensus/`basename "$consensus_file"`
