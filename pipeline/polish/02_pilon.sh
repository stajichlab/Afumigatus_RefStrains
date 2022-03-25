#!/usr/bin/bash -l
#SBATCH -p intel -N 1 -n 24 --mem 96gb --out logs/pilon.%a.log --array 1-12

module load AAFTF
MEM=96
IFS=,
SAMPLES=samples.csv
INDIR=asm/medaka
OUTDIR=asm/pilon
READDIR=data/Illumina

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
    for type in canu flye
    do
	POLISHED=$INDIR/$STRAIN/$type.polished.fasta
	mkdir -p $OUTDIR/$STRAIN
	PILON=$OUTDIR/$STRAIN/$type.pilon.fasta
	if [[ ! -f $PILON || $POLISHED -nt $PILON ]]; then
	    LEFT=$(ls $READDIR/$ILLUMINA | sed -n 1p)
	    RIGHT=$(ls $READDIR/$ILLUMINA | sed -n 2p)
	    AAFTF pilon -l $LEFT -r $RIGHT -it 10 -v -i $POLISHED -o $PILON -c $CPU --memory $MEM
	fi
    done
done


