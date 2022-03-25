#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 64 --mem 128gb --out logs/medaka.%a.log -a 1-12

module load medaka/1.6
module load workspace/scratch


READDIR=data/Nanopore
INDIR=asm
OUTDIR=asm/medaka

CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
	CPU=1
fi

N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
	echo "no value for SLURM ARRAY - specify with -a or cmdline"
    fi
fi

mkdir -p $OUTDIR
IFS=,
SAMPLES=samples.csv

sed -n ${N}p $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do

    mkdir -p $OUTDIR/$STRAIN
    if [ ! -f $OUTDIR/$STRAIN/canu.fasta ]; then
    	rsync -av $INDIR/canu/$STRAIN/$STRAIN.contigs.fasta $OUTDIR/$STRAIN/canu.fasta
    fi
    if [ ! -f $OUTDIR/$STRAIN/flye.fasta ]; then
    	rsync -av $INDIR/flye/$STRAIN/assembly.fasta $OUTDIR/$STRAIN/flye.fasta
    fi

    READS=$READDIR/$NANOPORE
    for type in canu flye
    do
	DRAFT=$OUTDIR/$STRAIN/$type.fasta
	BAM=$OUTDIR/$STRAIN/$type.calls_to_draft.bam
	if [[ ! -f $BAM ]]; then
	    mini_align -i ${READS} -r $DRAFT -m -p $SCRATCH/calls_to_draft -t $CPU
	    rsync -av $SCRATCH/calls_to_draft.bam $BAM
	    rsync -av $SCRATCH/calls_to_draft.bam.bai $BAM.bai
	fi
    done  
done


