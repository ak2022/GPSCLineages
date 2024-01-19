#!/bin/bash
REFSEQ=$1
NEWSEQS=$2

## Modules
module load ska.rust/0.3.4
module load gubbins/3.2.1

## Create a directory for the Outputs
mkdir ./Outputs

## Make a Ska Input file for the new sequences
paste <(ls "$MYPATH/$NEWSEQS" | sed 's/[.].*$//g') <(ls -d "./NewSeqs"/* | xargs realpath) > "./NewSkaInput.tsv"

## Build the Split k-mer files
bsub -J "BUILD" -o buildo.%J -e builde.%J -n4 -R "select[mem>2000] rusage[mem=2000] span[hosts=1]" -M 2000 "ska build -f ./NewSkaInput.tsv -k 31 -o "./NewBuild.skf --threads 4""

## When that's done, merge the new split k-mer file with the previous one
bsub -w "done(BUILD)" -J "MERGE" -M8000 -n16 -R "select[mem>8000] rusage[mem=8000]" -R "span[hosts=1]" -o ./Outputs/mergeo.%J -e ./Outputs/mergee.%J 'ska merge -o ./all_samples.skf ./NewBuild.skf'

## Map the split k-mer file to the reference sequence
bsub -w "done(MERGE)" -J "MAP" -M5000 -n16 -R "select[mem>5000] rusage[mem=5000]" -R "span[hosts=1]" -o ./Outputs/mapo.%J -e ./Outputs/mape.%J ska map -o ./SkaMap.aln --ambig-mask --threads 16 $REFSEQ "all_samples.skf"

## After mapping submit a job to the long queue to build the tree
bsub -w "done(MAP)" -J "TREE" -M8000 -R "select[mem>8000] rusage[mem=8000]" -n16 -R "span[hosts=1]" -o ./Outputs/Gubbinso.%J -e ./Outputs/Gubbinse.%J -q long 'run_gubbins.py --prefix Gubbins ./SkaMap.aln --threads 16 --first-tree-builder fasttree'