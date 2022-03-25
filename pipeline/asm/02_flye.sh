#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 64 -C ryzen --mem 128gb --out logs/flye.%a.log -a 1-12

module load flye

IFS=,
SAMPLES=samples.csv
OUTDIR=asm/flye
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
    flye --genome-size 30m -t $CPUS -o $OUTDIR/$STRAIN -i 5 --nano-raw $INDIR/$NANOPORE

done
