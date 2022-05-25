#!/usr/bin/bash -l
#SBATCH  --time 2-0:00:00 --ntasks 16 --nodes 1 --mem 24G --out logs/annotate_update.%a.log

module load funannotate
SAMPFILE=samples.csv
export PASAHOME=$HOME/.pasa

MEM=64G
CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
	CPU=1
fi

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
export PASACONF=$HOME/pasa.config.txt

SEED_SPECIES=aspergillus_fumigatus

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
SBT=$(realpath lib/sbt/Afum.sbt) # this can be changed

INDIR=genomes
OUTDIR=annotation
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi

IFS=,
SPECIES="Aspergillus fumigatus"
sed -n ${N}p $SAMPFILE | while read STRAIN NANOPORE ILLUMINA LOCUS
do
	BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
	for type in canu
	do
		 name=$STRAIN.$type
		 MASKED=$INDIR/${name}.pilon.masked.fasta
		 if [ ! -f $MASKED ]; then
				 echo "no masked file $MASKED"
				 exit
		 fi
     funannotate update --cpus $CPU -i $OUTDIR/$name --out $OUTDIR/$name \
		 --sbt $SBT --memory $MEM --pasa_db mysql
	done
done
