#!/bin/bash -l
#SBATCH --time 6-0:00:00 -c 24 -n 1 --nodes 1 --mem 96G --out logs/annotate_train.%a.log

module load funannotate
hostname
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
export PASACONF=$HOME/pasa.config.txt
echo $PASAHOME $PASACONF
IFS=,
SPECIES="Aspergillus fumigatus"
sed -n ${N}p $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do
    name=$BASE
    # only run on pilon now
    #POLISHED=medaka

    POLISHED=pilon
    # previous we were running flye and canu
    for type in canu
    do
        name=$STRAIN.$type
        MASKED=$INDIR/${name}.$POLISHED.masked.fasta
        echo "File in is $MASKED ($INDIR/${name}.$POLISHED.masked.fasta)"
        if [ ! -f $MASKED ]; then
            echo "no masked file $MASKED"
            exit
        fi
        if [ ! -f $RNAFOLDER/$STRAIN.fastq.gz ] && [ ! -f $RNAFOLDER/${STRAIN}_R1.fastq.gz ]; then
            echo "no RNA file $RNAFOLDER/$STRAIN.fastq.gz or $RNAFOLDER/${STRAIN}_R1.fastq.gz"
            exit
        fi
        # we could also do one more check for R2 files and run as single end if not found
        if [ -f $RNAFOLDER/${STRAIN}_R1.fastq.gz ]; then
            echo "paired end data detected for $STRAIN"
            funannotate train -i $MASKED -o $ODIR/${name}.$POLISHED \
                --jaccard_clip --species "$SPECIES" --isolate $STRAIN \
                --cpus $CPU --memory ${MEM} \
                --left $RNAFOLDER/${STRAIN}_R1.fastq.gz --right $RNAFOLDER/${STRAIN}_R2.fastq.gz \
                --pasa_db mysql
        else 
            echo "single end data detected for $STRAIN"                    
            funannotate train -i $MASKED -o $ODIR/${name}.$POLISHED \
                --jaccard_clip --species "$SPECIES" --isolate $STRAIN \
                --cpus $CPU --memory ${MEM} \
                --single $RNAFOLDER/$STRAIN.fastq.gz \
                --pasa_db mysql
        fi        
    done
done
