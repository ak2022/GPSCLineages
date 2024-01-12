#!/bin/bash

MYINPUT=$1
BATCHSIZE=$2
MYPATH=$PWD

## Create the correct directories
mkdir -p "$MYPATH/seqs"
mkdir -p "$MYPATH/batches"
mkdir -p "$MYPATH/builds"


# Create a file to store the outputs in
> $MYPATH/output.txt
echo "## JOB 1: BATCHING ##" >> $MYPATH/output.txt

## Where the input is the number of the GPSC
echo "GPSC Number to be anakysed: $1" >> $MYPATH/output.txt
echo "PWD: $MYPATH" >> $MYPATH/output.txt

## Create the Lane File using Monocle Data. If the GPSC is the same as the job index, print it to a lane file in that directory. 
> $MYPATH/lanes.txt
awk -F', *' '{ gsub(/"/, "", $88); if ($88 =='"$MYINPUT"') { gsub(/"/, "", $4); print $4 > "'"$MYPATH"'/lanes.txt" } }' $MYPATH/../monocle.csv \


## Collect the sequences from pf and add them to the seqs directory if there are more than 50 isolates. 
ISOLATES=$(wc -l < "$MYPATH/lanes.txt")
echo "Number of isolates in GPSC"$MYINPUT" is "$ISOLATES"" >> $MYPATH/output.txt
if [ $ISOLATES > 50 ]; then
    pf data -t file -i "$MYPATH/lanes.txt" -f fastq -l "$MYPATH/seqs"
else
    echo "Less than 50 sequences in the GPSC"$MYINPUT"; not continuing analysis." >> $MYPATH/output.txt
    exit 1
fi

## Add the Reference Sequence to the seqs directory. If no reference, exit.
echo "Checking for file /data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSC$MYINPUT/reference/GPSC"$MYINPUT"_reference.fasta" >> $MYPATH/output.txt
if [ -f "/data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSC$MYINPUT/reference/GPSC"$MYINPUT"_reference.fasta" ]; then
    # Copy the file if it exists
    cp /data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSC$MYINPUT/reference/GPSC"$MYINPUT"_reference.fasta $MYPATH/seqs
    echo "Reference file copied successfully." >> $MYPATH/output.txt
else
    # Print an error message and exit if the file does not exist
    echo "Error: The reference file could not be found. The name may be different to what is expected." >> $MYPATH/output.txt
    exit 1
fi

## Create a ska input file 
paste <(ls "$MYPATH/seqs" | sed 's/[.].*$//g') <(ls -d "$MYPATH/seqs"/* | xargs realpath) > "$MYPATH/ska_input.tsv"
echo "Full Ska Input file created, called ska_input.tsv" >> $MYPATH/output.txt

# Set the batch size
echo "Batch size is $BATCHSIZE" >> $MYPATH/output.txt

# Loop through each batch
for ((i = 1; i <= $ISOLATES; i += $BATCHSIZE)); do
  # Calculate the end line number for the current batch
  end_line=$((i + $BATCHSIZE - 1))

  # Ensure the end line number does not exceed the total number of lines
  if [ $end_line -gt $ISOLATES ]; then
    end_line=$ISOLATES
  fi

  # Perform the command on the lines in the current batch
  sed -n "${i},${end_line}p" "$MYPATH/ska_input.tsv" > "$MYPATH/batches/batch$i.tsv"
done

## Get a list of the batches and output it into the same directory
for file in $MYPATH/batches/batch*; do
    echo "$file" >> $MYPATH/batches/listbatches.txt
done

## Count the number of batches and store it in the output file
lines=$(wc -l < "$MYPATH/batches/listbatches.txt")
echo "Created $lines batches, listed in $MYPATH/batches/listbatches.txt" >> $MYPATH/output.txt
echo "BATCH COMPLETE" >> $MYPATH/output.txt
