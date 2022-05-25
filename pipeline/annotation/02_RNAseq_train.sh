#!/bin/bash -l
#SBATCH -p intel --time 6-0:00:00 --ntasks 24 --nodes 1 --mem 96G --out logs/annotate_train.%a.log

module unload miniconda3
module load funannotate

MEM=96G
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
ODIR=annotation
SAMPLES=samples.csv
RNAFOLDER=lib/RNASeq
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=$(wc -l $SAMPLES | awk '{print $1}')
if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPLES"
    exit
fi

export PASAHOME=$HOME/.pasa
echo $PASAHOME
IFS=,
SPECIES="Aspergillus fumigatus"
sed -n ${N}p $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do
    name=$BASE
    # previous we were running flye and canu
    for type in canu
    do
  	   name=$STRAIN.$type
	     MASKED=$INDIR/${name}.pilon.masked.fasta
	     echo "in is $MASKED ($INDIR/${name}.pilon.masked.fasta)"
	     if [ ! -f $MASKED ]; then
		       echo "no masked file $MASKED"
		       exit
	     fi
	     funannotate train -i $MASKED -o $ODIR/${name} \
   	   --jaccard_clip --species "$SPECIES" --isolate $STRAIN \
  	   --cpus $CPU --memory ${MEM} \
  	   --single $RNAFOLDER/$STRAIN.fastq.gz \
  	   --pasa_db mysql
    done
done
