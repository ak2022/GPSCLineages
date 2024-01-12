#!/bin/bash

MYINPUT=$1
BATCHSIZE=$2
MYPATH=$PWD

## Create the correct directories
mkdir -p "$MYPATH"
mkdir -p "$MYPATH/batches"
mkdir -p "$MYPATH/builds"


# Create a file to store the outputs in
> $MYPATH/output.txt
echo "## JOB 1: BATCHING ##" >> $MYPATH/output.txt

## Where the input is the number of the GPSC
echo "GPSC to be analysed: $1" >> $MYPATH/output.txt
echo "PWD: $MYPATH" >> $MYPATH/output.txt

ISOLATES=$(wc -l < "$MYPATH/lanes.txt")
echo "Number of isolates in GPSC"$MYINPUT" is "$ISOLATES"" >> $MYPATH/output.txt

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
echo "Created $lines batches" >> $MYPATH/output.txt
echo "$MYPATH/batches/listbatches.txt" >> $MYPATH/output.txt
echo "BATCH COMPLETE" >> $MYPATH/output.txt
