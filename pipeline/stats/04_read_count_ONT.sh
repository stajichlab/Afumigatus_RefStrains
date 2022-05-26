#!/usr/bin/bash

#SBATCH --nodes 1 --ntasks 24 --mem 24G -p short -J readCount --out logs/bbcount_ONT.%a.log --time 2:00:00
module load BBMap
module load workspace/scratch

hostname
MEM=24
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi
IFS=,
SAMPLES=samples.csv
INDIR=data
ASM=genomes
OUTDIR=$(realpath genomes)
OUTDIR=mapping_report

mkdir -p $OUTDIR
sed -n ${N}p $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do
    
    FASTQ=$(realpath $INDIR/Nanopore/$NANOPORE
    for type in canu flye necat
    do
	BASE=$STRAIN.$type.pilon
	SORTED=$(realpath $ASM/$BASE.fasta)
	if [ ! -f $SORTED ]; then
	    echo "No $SORTED file for $ASM/$BASE.fasta"
	    continue    
	elif [ ! -s $OUTDIR/${BASE}.bbmap_covstats.txt ]; then
	    pushd $SCRATCH
	    bbmap.sh -Xmx${MEM}g ref=$SORTED in=$FASTQ covstats=$OUTDIR/${BASE}.nanopore.bbmap_covstats.txt  statsfile=$OUTDIR/${BASE}.nanopore.bbmap_summary.txt
	    popd
	fi
    done
done
