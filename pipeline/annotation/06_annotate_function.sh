#!/usr/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=16 --mem 24gb
#SBATCH --output=logs/annotate_function.%a.log
#SBATCH --time=2-0:00:00
#SBATCH -p intel -J 06annotfunc

module unload miniconda3
module load funannotate
module load phobius

export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
CPUS=$SLURM_CPUS_ON_NODE
if [ -z $CPUS ]; then
  CPUS=1
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
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
  echo "$N is too big, only $MAX lines in $SAMPFILE"
  exit
fi
TEMPLATE=$(realpath lib/sbt/Afum.sbt)
SPECIES="Aspergillus fumigatus"
IFS=,
sed -n ${N}p $SAMPFILE | while read STRAIN NANOPORE ILLUMINA LOCUSTAG
do
  BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
  STRAIN_NOSPACE=$(echo -n "$STRAIN" | perl -p -e 's/\s+/_/g')
  echo "$BASE"
  for type in canu
  do
     name=$STRAIN.$type
#  TEMPLATE=$(realpath lib/sbt/$STRAIN_NOSPACE.sbt)
#  if [ ! -f $TEMPLATE ]; then
#    echo "NO TEMPLATE for $name"
#    exit
#  fi
    ANTISMASHRESULT=$OUTDIR/$name/annotate_misc/antiSMASH.results.gbk
    echo "$name $species $BASE"
    if [[ ! -f $ANTISMASHRESULT && -d $OUTDIR/$name/antismash_local ]]; then
      ANTISMASH=$OUTDIR/$name/antismash_local/$BASE.gbk
      if [ ! -f $ANTISMASH ]; then
        echo "CANNOT FIND $ANTISMASH in $OUTDIR/$name/antismash_local"
      else
        rsync -a $ANTISMASH $ANTISMASHRESULT
      fi
    fi
    # need to add detect for antismash and then add that
   funannotate annotate --sbt $TEMPLATE --busco_db $BUSCO -i $OUTDIR/$name --species "$SPECIES" --strain "$STRAIN" --cpus $CPUS $MOREFEATURE $EXTRAANNOT
 done
done
