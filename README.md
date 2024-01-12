# Ska-Based GPSC Lineage Reconstruction
Reconstructing the GPSC lineages using [Ska2]([https://pages.github.com/](https://github.com/bacpop/ska.rust))

# First Time Reconstruction 1️⃣ 
## Setup 
1) Load the ska module: 
```
module load ska.rust/0.3.4
```

2) Get the scripts, either here:
```
cp data/pam/team284/ak47/scratch/LineageScripts/* ./GPSCScripts
```
or as part of this Github repo

3) Make sure you have the monocle database available in your the GPSCx working directory if using the built-in pf based sequence retrieval.

4) Create a directory called GPSCx (whichever one you want to analyse) and navigate into it. 


## Batching - batching_pf.sh 📦

Get the sequences needed for the analysis. You can use the batching_pf.sh script to import your sequences and do all the batching simultaneously. You'll need to have the monocle database for this. It takes two arguments - the GPSC you wish to reconstruct a lineage for, and the size of batches for later analysis. The script will create a lane file from the monocle data for any sequences assigned to the GPSC of interest. The batch size default is 50 - more batches means fewer sequences per batch, but more jobs in the job array. 50 seems to be a good mid point but I have no data to support that.  

This would submit a job to gather sequence IDs and paths for anything in monocle assigned to GPSC15. It will also look for the Reference Sequence in the form:
```
/data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSCx/reference/GPSCx_reference.fasta
```
And it will throw and error and quit if it cannot find it. 

Once the sequences were gathered and stored in the directory ./seqs, they would be split into batches of fifty (and one batch of whatever the remainder is), and separate ska input files would be made for each batch. The ska input files can be found in the directory ./batches, along with a file listing the paths to each of those files. 
```
bsub -M1000 -R "select[mem>1000] rusage[mem=1000]" -R "span[hosts=1]" -o Batcho.%J -e Batche.%J '../GPSCScripts/batching_pf.sh 15 50'
```


## Batching - batching.sh 📦
Batching without pf assumes that you already have the sequences you want to analyse in the directory ./seqs, along with the reference sequence in the format GPSCx_reference.fasta

Therefore, you don't need to specify the GPSC number, only the batch size if you want it to be not 50. The output files are the same. 
```
bsub -M5000 -R "select[mem>5000] rusage[mem=5000]" -R "span[hosts=1]" -o Batcho.%J -e Batche.%J '../GPSCScripts/batching.sh 50'
```


## Building 🧱
Next, the split k-mer files need to be constructed for each batch. A default size of 31 is used. If you check the output.txt file you can see how many batches have been created - this is your maximum job index number. 

The script building.sh uses the file ./batches/listbatches.txt to build a split k-mer file for each batch of sequences. The best thing to do is to run this as a job array like so. Each job will output a .skf file in the directory ./builds.  

```
bsub -o buildo.%J -e builde.%J -n4 -R "select[mem>2000] rusage[mem=2000] span[hosts=1]" -M 2000 -J "build[1-5]" ../GPSCScripts/building.sh
```


## Merging 
Ska allows you to merge multiple .skf files into one larger file. This is super useful as it allows for the parallelisation of large numbers of sequences with the batching, and you can create split k-mer files for any new sequences and just tag them on here without having the rebuild the files for all the other sequences that were already present. Hooray! 🎉

This should be fairly quick ad not need much memory. The output is a file called all_samples.skf

```
bsub -M8000 -n16 -R "select[mem>8000] rusage[mem=8000]" -R "span[hosts=1]" -o mergeo.%J -e mergee.%J 'ska merge -o all_samples ./builds/build*'
```


## Mapping 🗺️
Now the split k-mer file will be mapped to the reference sequence to create a pseudoalignment that can be used for gubbins etc. 
```
bsub -M5000 -n16 -R "select[mem>5000] rusage[mem=5000]" -R "span[hosts=1]" -o o.%J -e e.%J 'ska map -o ./SkaMap.aln --ambig-mask --threads 16 "./seqs/GPSC15_reference.fasta" "all_samples.skf"'
```

## Tree Time 🌳
You can now use the file SkaMap.aln as an input for Gubbins like so:

```
bsub -M8000 -R "select[mem>8000] rusage[mem=8000]" -n16 -R "span[hosts=1]" -o Gubbinso.%J -e Gubbinse.%J -q long 'run_gubbins.py --prefix Gubbins ./SkaMap.aln --threads 16 --first-tree-builder fasttree'
```
And you're definitely going to want to leave this in the long queue. 


# Adding New Data ⏩
One benefit of this method is that you can add on new samples. To do this, move the new sequences into their own directory e.g. ./NewSeqs

Create a Ska Input file for these new sequences 
```
paste <(ls "$MYPATH/GPSC$MYINPUT/seqs" | sed 's/[.].*$//g') <(ls -d "./NewSeqs"/* | xargs realpath) > "./NewSkaInput.tsv"
```

Build a split k-mer file for these new sequences. 
```
bsub -o buildo.%J -e builde.%J -n4 -R "select[mem>2000] rusage[mem=2000] span[hosts=1]" -M 2000 "ska build -f ./NewSkaInput.tsv -k 31 -o "./NewBuild.skf --threads 4"
```

Merge it with the previous all_samples.skf file

```
bsub -M5000 -n16 -R "select[mem>5000] rusage[mem=5000]" -R "span[hosts=1]" -o mergeo.%J -e mergee.%J 'ska merge -o all_samples_v2 ./all_samples.skf ./NewBuild.skf'
```

Map to the reference as above and use in Gubbins as above! 




