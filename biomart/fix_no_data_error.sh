#!/bin/bash

infile=$1
error_message="Sequence unavailable"

if grep -q "$error_message" "$infile"; then
	# Author: don_crissti https://unix.stackexchange.com/a/213395
	echo "$(grep -n -B1 "$error_message" "$infile" | \
	sed -n 's/^\([0-9]\{1,\}\).*/\1d/p' | \
	sed "$(cat)" "$infile")" > "$infile"
fi
