#!/bin/bash

replicate=$1
index=$2

number=$(echo "$index+7*($replicate-2)" | bc)
echo $(printf "%02d" $number)
