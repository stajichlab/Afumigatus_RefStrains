#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 24  --mem 64gb --out logs/ragtag_correct.%a.log

module load ragtag
CPUS=$SLURM_CPUS_ON_NODE
if [ -z $CPUS ]; then
 CPUS=1
fi


IFS=,
SAMPLES=samples.csv
INDIR=genomes
OUTDIR=asm/merge_ragtag
mkdir -p $OUTDIR
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
	echo "no value for SLURM ARRAY - specify with -a or cmdline"
    fi
fi

sed -n ${N}p $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do
	CANU=$INDIR/$STRAIN.canu.pilon.fasta
	FLYE=$INDIR/flye_noscaffold/$STRAIN.flye.pilon.fasta
	if [ ! -f $CANU ]; then
		echo "no CANU file $CANU"
		exit
	elif [ ! -f $FLYE ]; then
		echo "no FLYE file $FLYE"
		exit
	fi
	ragtag.py correct -w $CANU $FLYE -o $OUTDIR/$STRAIN.canu_corrected_by_flye -t $CPUS -f 100 -T ont -v 500 --aligner unimap -R data/Nanopore/$NANOPORE 
done

