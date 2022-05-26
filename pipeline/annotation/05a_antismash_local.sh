#!/usr/bin/bash -l
#SBATCH --nodes 1 --ntasks 8 --mem 16G --out logs/annotate_antismash.%a.log -J antismash

module load antismash
which antismash
hostname
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

INPUTFOLDER=update_results

IFS=,
sed -n ${N}p $SAMPFILE | while read STRAIN NANOPORE ILLUMINA LOCUSTAG
do
    echo "STRAIN is $STRAIN LOCUSTAG is $LOCUSTAG"
    BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
    for type in canu
    do
	name=$STRAIN.$type
	
	if [ ! -d $OUTDIR/$name ]; then
	    echo "No annotation dir for ${name}"
	    exit
	fi
	echo "processing $OUTDIR/$name"
	if [[ ! -d $OUTDIR/$name/antismash_local && ! -s $OUTDIR/$name/antismash_local/index.html ]]; then
	    #	antismash --taxon fungi --output-dir $OUTDIR/$name/antismash_local  --genefinding-tool none \
		#    --asf --fullhmmer --cassis --clusterhmmer --asf --cb-general --pfam2go --cb-subclusters --cb-knownclusters -c $CPU \
		#    $OUTDIR/$name/$INPUTFOLDER/*.gbk
	    time antismash --taxon fungi --output-dir $OUTDIR/$name/antismash_local \
		 --genefinding-tool none --fullhmmer --clusterhmmer --cb-general \
		 --pfam2go -c $CPU $OUTDIR/$name/$INPUTFOLDER/*.gbk
	fi
    done
done
