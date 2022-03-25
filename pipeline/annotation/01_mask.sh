#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 24 --nodes 1 --mem 24G --out logs/annotate_mask.%a.log

module unload miniconda3

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=RepeatMasker_run

LIBRARY=$(realpath lib/Afum95_Fungi_repeats.lib)
SAMPLES=samples.csv
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

IFS=,
SPECIES="Aspergillus fumigatus"
sed -n ${N}p $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do
    name=$BASE
    for type in flye canu
    do
	name=$STRAIN.$type
	if [ ! -f $INDIR/${name}.pilon.sorted.fasta ]; then
	    if [ -f $INDIR/${name}.pilon.fasta ]; then
		module load AAFTF
		AAFTF sort -i $INDIR/${name}.pilon.fasta -o $INDIR/${name}.pilon.sorted.fasta
		module unload AAFTF
	    else
		echo "Cannot find $name.pilon.fasta in $INDIR - may not have been run yet"
		exit
	    fi
	fi	
	
	if [ ! -s $INDIR/${name}.pilon.masked.fasta ]; then
	
	    mkdir -p $OUTDIR/${name}
	    if [ ! -f $OUTDIR/${name}/${name}.pilon.sorted.fasta.masked ]; then
	    	module load RepeatMasker
	    	RepeatMasker -e ncbi -xsmall -s -pa $CPU -lib $LIBRARY -dir $OUTDIR/${name} -gff $INDIR/${name}.pilon.sorted.fasta 
	    fi
	    rsync -a $OUTDIR/${name}/${name}.pilon.sorted.fasta.masked $INDIR/${name}.pilon.masked.fasta
	else
	    echo "Skipping ${name} as masked file already exists"
	fi
    done
done
