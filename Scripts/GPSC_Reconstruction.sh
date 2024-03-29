#!/bin/bash
## Get the reference sequence name from the command line
REFSEQ=$1

## Load the modules
module load ska.rust/0.3.4
module load gubbins/3.2.1

## Report Back
echo "Reference Sequence path is $REFSEQ"

## Create a directory for the Outputs
mkdir ./Outputs

## Batch the Sequences
echo "Batching..."
bsub -J "BATCH" -M20 -R "select[mem>20] rusage[mem=20]" -R "span[hosts=1]" -o ./Outputs/batcho.%J -e ./Outputs/batche.%J ./Scripts/batching.sh

## Wait until the final batch file exists - this is used as a marker that batching has finished 
until [ -e ./Outputs/BATCH.txt ]; do
  sleep 1
done
echo BATCH file  exists, batching complete

## Count the number of batches and report back
BATCHNUMBER=$(wc -l < ./batches/listbatches.txt)
echo "Total of $BATCHNUMBER batches"

## Build split k-mer files for each batch
bsub -w "done(BATCH)" -o ./Outputs/buildo.%J -e ./Outputs/builde.%J -n4 -R "select[mem>2000] rusage[mem=2000] span[hosts=1]" -M 2000 -J "BUILD[1-$BATCHNUMBER]" ./Scripts/building.sh

## Merge the build files together
bsub -w "done(BUILD[1-$BATCHNUMBER])" -J "MERGE" -M8000 -n16 -R "select[mem>8000] rusage[mem=8000]" -R "span[hosts=1]" -o ./Outputs/mergeo.%J -e ./Outputs/mergee.%J 'ska merge -o all_samples ./builds/build*'

## Map the split k-mer files
bsub -w "done(MERGE)" -J "MAP" -M20000 -n16 -R "select[mem>20000] rusage[mem=20000]" -R "span[hosts=1]" -o ./Outputs/mapo.%J -e ./Outputs/mape.%J ska map -o ./SkaMap.aln --ambig-mask --threads 16 $REFSEQ "all_samples.skf"

## Build the trees
bsub -w "done(MAP)" -J "TREE" -M8000 -R "select[mem>8000] rusage[mem=8000]" -n48 -R "span[hosts=1]" -o ./Outputs/Gubbinso.%J -e ./Outputs/Gubbinse.%J -q long 'run_gubbins.py --prefix Gubbins ./SkaMap.aln --threads 48 --first-tree-builder fasttree'