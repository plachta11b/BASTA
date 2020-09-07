#!/bin/bash

file=$1

docker_container="docker run -i quay.io/biocontainers/bedops:2.4.39--hc9558a2_0 gff2bed"

cat $file | docker_container > $file.bed
cat $file.bed | sed 's/^chr//' > $file.nochr.bed
