#!/usr/bin/bash
#SBATCH -p short --mem 128gb -N 1 -n 32 --out logs/STAR.%a.log

module load star
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

INDIR=db
IDX=index
for file in $(ls db/*.fasta db/*.fna)
do
    IDX_T=$(basename $file .fasta)
    IDX_T=$(basename ${IDX_T} .fna)
    IDXFOLDER=$IDX/${IDX_T}
    if [ ! -d $IDXFOLDER ]; then
	STAR --runThreadN $CPU --runMode genomeGenerate --genomeDir $IDXFOLDER --genomeFastaFiles $file --genomeSAindexNbases 11
    fi
done
