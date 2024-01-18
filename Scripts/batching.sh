#!/bin/bash

MYINPUT=$1
BATCHSIZE=$2
MYPATH=$PWD

## Create the correct directories
mkdir -p "$MYPATH"
mkdir -p "$MYPATH/batches"
mkdir -p "$MYPATH/builds"

## Count the number of sequences
ISOLATES=$(wc -l < "$MYPATH/lanes.txt")

## Create a ska input file 
paste <(ls "$MYPATH/seqs" | sed 's/[.].*$//g') <(ls -d "$MYPATH/seqs"/* | xargs realpath) > "$MYPATH/Outputs/ska_input.tsv"

# Loop through each batch
for ((i = 1; i <= $ISOLATES; i += $BATCHSIZE)); do
  # Calculate the end line number for the current batch
  end_line=$((i + $BATCHSIZE - 1))

  # Ensure the end line number does not exceed the total number of lines
  if [ $end_line -gt $ISOLATES ]; then
    end_line=$ISOLATES
  fi

  # Perform the command on the lines in the current batch
  sed -n "${i},${end_line}p" "$MYPATH/Outputs/ska_input.tsv" > "$MYPATH/batches/batch$i.tsv"
done

## Get a list of the batches and output it into the same directory
for file in $MYPATH/batches/batch*; do
    echo "$file" >> $MYPATH/batches/listbatches.txt
done

echo "BATCHING COMPLETED" >> $MYPATH/Outputs/BATCH.txt

