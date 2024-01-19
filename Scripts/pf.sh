#!/bin/bash

MYINPUT=$1
MYPATH=$PWD

# Modules
module load pf 

## Create the correct directories
mkdir -p "$MYPATH/seqs"

# Create a file to store the pf_outputs in
> $MYPATH/pf_output.txt
echo "## JOB 1: BATCHING ##" >> $MYPATH/pf_output.txt

## Where the input is the number of the GPSC
echo "GPSC Number to be analysed: $1" >> $MYPATH/pf_output.txt
echo "PWD: $MYPATH" >> $MYPATH/pf_output.txt

## Create the Lane File using Monocle Data. If the GPSC is the same as the job index, print it to a lane file in that directory. 
> $MYPATH/lanes.txt
awk -F', *' '{ gsub(/"/, "", $88); if ($88 =='"$MYINPUT"') { gsub(/"/, "", $4); print $4 > "'"$MYPATH"'/lanes.txt" } }' $MYPATH/../monocle.csv \

## Collect the sequences from pf and add them to the seqs directory if there are more than 50 isolates. 
ISOLATES=$(wc -l < "$MYPATH/lanes.txt")
echo "Number of isolates in GPSC"$MYINPUT" is "$ISOLATES"" >> $MYPATH/pf_output.txt
if [ $ISOLATES > 50 ]; then
    pf data -t file -i "$MYPATH/lanes.txt" -f fastq -l "$MYPATH/seqs"
else
    echo "Less than 50 sequences in the GPSC"$MYINPUT"; not continuing analysis." >> $MYPATH/pf_output.txt
    exit 1
fi

## Add the Reference Sequence to the seqs directory. If no reference, exit.
echo "Checking for file /data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSC$MYINPUT/reference/GPSC"$MYINPUT"_reference.fasta" >> $MYPATH/pf_output.txt
if [ -f "/data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSC$MYINPUT/reference/GPSC"$MYINPUT"_reference.fasta" ]; then
    # Copy the file if it exists
    cp /data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSC$MYINPUT/reference/GPSC"$MYINPUT"_reference.fasta $MYPATH/seqs
    echo "Reference file copied successfully." >> $MYPATH/pf_output.txt
else
    # Print an error message and exit if the file does not exist
    echo "Error: The reference file could not be found. The name may be different to what is expected." >> $MYPATH/pf_output.txt
    exit 1
fi