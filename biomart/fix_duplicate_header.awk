#!/usr/bin/awk -f

# from Brian on stackoverflow
# https://stackoverflow.com/questions/34771843/mark-duplicate-headers-in-a-fasta-file

BEGIN {
    OFS="\n";
    ORS=RS=">";
} 
{
    name = $1;
    $1 = "";
    suffix = names[name] ? "|seq_reg" names[name] : "";
    print name suffix $0, "\n";
    names[name]++;
}

