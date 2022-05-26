#!/usr/bin/bash -l
#SBATCH -p intel -N 1 -n 24 --mem 96gb --out logs/nextPolish.%a.log --array 1-12

module load NextPolish

MEM=96
IFS=,
SAMPLES=samples.csv
INDIR=asm/NextDenovo
TEMPLATE=lib/NextPolish.cfg
OUTDIR=asm/NextPolish
ONTREADDIR=$(realpath data/Nanopore)
ILLREADDIR=$(realpath data/Illumina)
GENOME=asm/NextPolish

N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
	echo "no value for SLURM ARRAY - specify with -a or cmdline"
    fi
fi

CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
	CPU=1
fi

mkdir -p $OUTDIR
sed -n ${N}p $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do
    ND=$INDIR/$STRAIN/01_rundir/03.ctg_graph/nd.asm.fasta
    mkdir -p $OUTDIR/$STRAIN
    rsync -a $ND $OUTDIR/$STRAIN/nd.asm.fasta
    NP=$OUTDIR/$STRAIN/nextpolish.fasta
    ls  $ILLREADDIR/$ILLUMINA > $OUTDIR/$STRAIN/sgs.fofn
    ls  $ONTREADDIR/$NANOPORE > $OUTDIR/$STRAIN/lgs.fofn 
    rsync -a $TEMPLATE $OUTDIR/$STRAIN
    pushd $OUTDIR/$STRAIN
    nextPolish NextPolish.cfg
done


