#!/usr/bin/bash -l
#SBATCH -p batch -N 1 -n 2 --mem 8gb --out logs/NextDenovo.%a.log -a 1-12

module load NextDenovo

IFS=,
SAMPLES=samples.csv
OUTDIR=asm/NextDenovo
INDIR=data/Nanopore
TEMPLATECONFIG=lib/NextDenovo.cfg

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
    realpath $INDIR/$NANOPORE > $OUTDIR/$STRAIN/reads.fofn
    cp $TEMPLATECONFIG $OUTDIR/$STRAIN/NextDenovo.cfg
    pushd $OUTDIR/$STRAIN
    nextDenovo NextDenovo.cfg
    popd
done
