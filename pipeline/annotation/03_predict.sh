#!/usr/bin/bash -l
#SBATCH -p batch --time 3-0:00:00 --ntasks 16 --nodes 1 --mem 24G --out logs/annotate_predict.%a.log

module load funannotate

# this will define $SCRATCH variable if you don't have this on your system you can basically do this depending on
# where you have temp storage space and fast disks
module load workspace/scratch

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

BUSCO=eurotiomycetes_odb10 # This could be changed to the core BUSCO set you want to use
INDIR=genomes
OUTDIR=annotation
mkdir -p $OUTDIR
SAMPFILE=samples.csv

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=$(wc -l $SAMPFILE | awk '{print $1}')

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db

SEED_SPECIES=aspergillus_fumigatus

IFS=,
SPECIES="Aspergillus fumigatus"
sed -n ${N}p $SAMPFILE | while read STRAIN NANOPORE ILLUMINA LOCUSTAG
do
    echo "STRAIN is $STRAIN LOCUSTAG is $LOCUSTAG"
    BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
    for type in canu
    do
       name=$STRAIN.$type
       MASKED=$INDIR/${name}.pilon.masked.fasta
       echo "masked is $MASKED ($INDIR/${name}.pilon.masked.fasta)"
       if [ ! -f $MASKED ]; then
           echo "no masked file $MASKED"
           exit
       fi
      funannotate predict --cpus $CPU --keep_no_stops --SeqCenter $SEQCENTER \
       --busco_db $BUSCO --optimize_augustus \
	     --strain $STRAIN --min_training_models 100 \
       --AUGUSTUS_CONFIG_PATH $AUGUSTUS_CONFIG_PATH \
	     -i $MASKED --name $LOCUSTAG \
       --protein_evidence $FUNANNOTATE_DB/uniprot_sprot.fasta \
	     -s "$SPECIES" -o $OUTDIR/${name} --busco_seed_species $SEED_SPECIES
  done
done
