#!/bin/bash -l
#SBATCH --ntasks 24 --nodes 1 --mem 96G -p intel
#SBATCH --time 72:00:00 --out logs/annotate_iprscan.%a.log
module unload miniconda3
module load funannotate
module load iprscan
CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
OUTDIR=annotation
SAMPFILE=samples.csv
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
sed -n ${N}p $SAMPFILE | while read STRAIN NANOPORE ILLUMINA LOCUSTAG
do
    SEQCENTER=MiGS
    echo "STRAIN is $STRAIN LOCUSTAG is $LOCUSTAG"
    BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
    for type in canu
    do
       name=$STRAIN.$type
       if [ ! -d $OUTDIR/$name ]; then
	   echo "No annotation dir for ${name}"
	   exit
       fi
       mkdir -p $OUTDIR/$name/annotate_misc
       XML=$OUTDIR/$name/annotate_misc/iprscan.xml
       IPRPATH=$(which interproscan.sh)
       if [ ! -f $XML ]; then
	   time funannotate iprscan -i $OUTDIR/$name -o $XML -m local -c $CPU --iprscan_path $IPRPATH
       fi
    done
done
