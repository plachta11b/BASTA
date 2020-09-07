#!/bin/bash

arg_prefix=$1
arg_fdr=$2
arg_gene_count=$3
#arg_motif_count=$4

if [[ $# -lt 3 ]] ; then
        echo 'not enough arguments'
        #echo 'call: ./run_pipeline.sh \$prefix \$fdr \$gene_count \$motif_count'
        #echo 'call: ./run_pipeline.sh default 0.01 50 10'
        echo 'call: ./run_pipeline.sh \$prefix \$fdr \$gene_count'
        echo 'call: ./run_pipeline.sh default 0.01 50'
        exit 1
fi

# remove slash '/' and space ' '
prefix_arg_sanitized=$(echo $1 | sed 's/\///g' | sed 's/ //g')
prefix=${prefix_arg_sanitized:-"default"}  # If variable not set or null, use default.

echo "using prefix: $prefix"
echo "using fdr: $arg_fdr"
echo "using gene count: $arg_gene_count"

#todo bash test number
#$arg_fdr (float)
#$arg_gene_count (int)
./configure.sh || $(echo "configuration error"; exit 1)
./make_filter.sh $prefix $arg_fdr $arg_gene_count || $(echo "unable to make filter"; exit 1)
./filter_bam.sh $prefix "bam" false || $(echo "bam filtration failed"; exit 1)
./make_fasta.sh $prefix || $(echo "bam to fasta conversion failed"; exit 1)
#./run_dreme.sh $prefix 8 $motif_count || $(echo "de novo motif search failed";exit 1)

exit 0
