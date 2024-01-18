#!/bin/bash
## The job array input file should be the list of batches produced at the end of batching.sh
MYPATH=$PWD
MYLIST=$MYPATH/batches/listbatches.txt
MYINPUT=$( sed -n "${LSB_JOBINDEX}p" $MYLIST)

## Ska Build with a k-mer size of 31
ska build -f "$MYINPUT" -k 31 -o "$MYPATH/builds/build$LSB_JOBINDEX" --threads 4
