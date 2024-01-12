#!/bin/bash
## The job array input file should be the list of batches produced at the end of batching.sh
MYPATH=$PWD
MYLIST=$MYPATH/batches/listbatches.txt
MYINPUT=$( sed -n "${LSB_JOBINDEX}p" $MYLIST)
echo "Buld work directory is $(pwd)" >> $MYPATH/output.txt
echo "## JOB 2.$LSB_JOBINDEX: BUILDING $MYINPUT ##" >> $MYPATH/output.txt

## Ska Build with a k-mer size of 31
ska build -f "$MYINPUT" -k 31 -o "$MYPATH/builds/build$LSB_JOBINDEX" --threads 4 \
&& echo "Ska Build for $MYINPUT complete, and named build$LSB_JOBINDEX.skf." >> $MYPATH/output.txt
