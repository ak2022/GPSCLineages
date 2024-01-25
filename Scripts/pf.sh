#!/bin/bash
GPSC=$1
MYPATH=$PWD

# Modules
module load pf 

## Create the correct directories
mkdir -p "$MYPATH/seqs"

# Create a file to store the pf_outputs in
> $MYPATH/pf_output.txt
echo "Gathering Sequences for GPSC$GPSC"

## Create the Lane File using Monocle Data. If the GPSC is the same as the job index, print it to a lane file in that directory. 
> $MYPATH/lanes.txt
awk -F', *' '{ gsub(/"/, "", $88); if ($88 =='"$GPSC"') { gsub(/"/, "", $4); print $4 > "'"$MYPATH"'/lanes.txt" } }' $MYPATH/../monocle.csv \

## Collect the sequences from pf and add them to the seqs directory if there are more than 50 isolates. 
ISOLATES=$(wc -l < "$MYPATH/lanes.txt")
echo "Number of isolates in GPSC"$GPSC" is "$ISOLATES""
pf data -t file -i "$MYPATH/lanes.txt" -f fastq -l "$MYPATH/seqs"

## Add the Reference Sequence to the seqs directory. If no reference, exit.
echo "Checking for file /data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSC$GPSC/reference/GPSC"$GPSC"_reference.fasta" >> $MYPATH/pf_output.txt
if [ -f "/data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSC$GPSC/reference/GPSC"$GPSC"_reference.fasta" ]; then
    # Copy the file if it exists
    cp /data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSC$GPSC/reference/GPSC"$GPSC"_reference.fasta $MYPATH/seqs
    echo "Reference file copied successfully." >> $MYPATH/pf_output.txt
else
    # Print an error message and exit if the file does not exist
    echo "Error: The reference file could not be found. The name may be different to what is expected." >> $MYPATH/pf_output.txt
    exit 1
fi