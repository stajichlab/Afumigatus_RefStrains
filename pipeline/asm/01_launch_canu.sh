#!/usr/bin/bash -l
module unload java
module load canu

mkdir -p logs

IFS=,
SAMPLES=samples.csv
OUTDIR=asm/canu
INDIR=data/Nanopore
mkdir -p $OUTDIR
cat $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
#while read STRAIN NANOPORE ILLUMINA LOCUS
do
    canu -p $STRAIN -d $OUTDIR/$STRAIN genomeSize=30m useGrid=true -nanopore $INDIR/$NANOPORE
done
#done < $SAMPLES

