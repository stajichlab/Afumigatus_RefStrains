#!/usr/bin/bash -l
#SBATCH -p short -C cascade -N 1 -n 1 -c 16 --mem 64gb --out logs/hifiasm.%a.log -a 1-16

module load hifiasm

IFS=,
SAMPLES=samples.csv
OUTDIR=asm/hifiasm
INDIR=data/Nanopore
mkdir -p $OUTDIR

CPUS=$SLURM_CPUS_ON_NODE
if [ -z $CPUS ]; then
 CPUS=1
fi

N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
	echo "no value for SLURM ARRAY - specify with -a or cmdline"
    fi
fi

sed -n ${N}p $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do
	mkdir -p $OUTDIR/$STRAIN
	hifiasm -t $CPUS -o $OUTDIR/$STRAIN/$STRAIN --ont $INDIR/$NANOPORE

done
