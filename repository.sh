#!/bin/bash

script_directory=`dirname "$0"`

#bcftools_old biocontainers/bcftools:v1.9-1-deb_cv1 ~/singularity/bcftools_old.simg
#gff2bed plachta11b/gff2bed:0.1 ~/singularity/gff2bed.simg

read -r -d '' containers <<- EOM
	gffread zavolab/gffread:0.11.7-slim ~/singularity/gffread.simg
	gffutils quay.io/biocontainers/gffutils:0.10.1--py_0 ~/singularity/gffutils.simg
	samtools kfdrc/samtools:1.9 ~/singularity/samtools.simg
	vcfutils kfdrc/vcfutils:latest ~/singularity/vcfutils.simg
	bcftools lifebitai/bcftools:1.10.2-51-ga205d5c ~/singularity/bcftools.simg
	bwa biocontainers/bwa:v0.7.17-3-deb_cv1 ~/singularity/bwa.simg
	seqtk biocontainers/seqtk:v1.3-1-deb_cv1 ~/singularity/seqtk.simg
	bedtools biocontainers/bedtools:v2.28.0_cv2 ~/singularity/bedtools.simg
	bedops quay.io/biocontainers/bedops:2.4.39--hc9558a2_0 ~/singularity/bedops.simg
	biomart plachta11b/biomart-xml-client:0.3-ensembl ~/singularity/biomart.simg
	crossmap crukcibioinformatics/crossmap ~/singularity/crossmap.simg
	ucsc_gff2bed plachta11b/ucsc_gff2bed:0.1 ~/singularity/ucsc_gff2bed.simg
EOM

echo "$containers"
