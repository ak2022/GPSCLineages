# Ska-Based GPSC Lineage Reconstruction 🦠
Reconstructing the GPSC lineages using [Ska2](https://github.com/bacpop/ska.rust)

This method is faster than the previous multiple_mappings_to_bam method. It is also much more easy to add new sequences as they come in to each GPSC lineage. 

The workflow is that the sequences to be analysed are batched, and a split k-mer file is built for each batch as part of a job array. Once this has finished, the split k-mer files can be joined together into a single .skf file. Mapping is then done to create an alignment file, which can then be used in [Gubbins](https://github.com/nickjcroucher/gubbins) to produce the final tree.  

## Software Dependencies 💿
These are checked for/installed in the script, but just in case:

```
module load ska.rust/0.3.4
module load gubbins/3.2.1
module load bsub.py
```

## File Dependencies 📄
This script requires you to be in the working directory where you want to store you results - for example, if you're running GPSC15 I'd recommend being in a wd called GPSC15.

Within that, you should have a directory called seqs which contains the sequences you'd like to analyse. This should also include the reference sequence for that particular GPSC, which can be copied to the seqs directory using: 
```
cp /data/pam/team284/sl28/scratch/gps2245/trumps/GPSCs_v2/GPSC_files/GPSCx/reference/GPSCx_reference.fasta ./seqs
```
You also need the directory Scripts, containing the scripts in this repo. 

A new directory, ./Outputs, will be created and the outputs for each job are stored there. 


# First Time Reconstruction 1️⃣ 
Run the script: 

```
./Scripts/GPSC_Reconstruction.sh <Path to reference sequence> <GPSC> <Batch Size>
```

This will automatically submit jobs to bsub, with each job waiting until the one before has finished. 

# Adding New Data ⏩
One benefit of this method is that you can add on new samples. To do this, put new sequences into their own directory e.g. ./NewSeqs. The final split k-mer file from the initial run must be available in the currentworking directory and called all_samples.skf. This script will then create a new split k-mer file for the new sequences, merge it with the previous split k-mer file, and proceed to map the sequences and create a tree as previously.

```
./Scripts/AddingSequences <Path to reference sequence> <Path to new sequences> <Batch Size>
```

# Beware ⚠️
- Gubbins can take a long time. A really long time. The job is set to enter the long queue, but if it times out, you can run it again without having to redo everything by submitting. You can also try basement for a longer runtime. 
  
```
bsub -J "TREE" -M8000 -R "select[mem>8000] rusage[mem=8000]" -n16 -R "span[hosts=1]" -o ./Outputs/Gubbinso.%J -e ./Outputs/Gubbinse.%J -q basement 'run_gubbins.py --prefix Gubbins ./SkaMap.aln --threads 16 --first-tree-builder fasttree'
```

- If an earlier job fails, say due to there not being enough memory, the other jobs won't automatically exit. You'll need to use bkill to do this manually or wait for them to time out. 


