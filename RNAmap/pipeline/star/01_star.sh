#!/usr/bin/bash
#SBATCH --mem 64gb -N 1 -c 32 -n 1 --out logs/STAR.%a.log

module load star
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi
OUTDIR=results/STAR
IDX=index
INDIR=fastq
Af293=$IDX/FungiDB-68_AfumigatusAf293_Genome
A1163=$IDX/FungiDB-68_AfumigatusA1163_Genome
SAMPLEFILE=samples.csv
FASTQEXT=fastq.gz
FWDEXT=R1
REVEXT=R2
IFS=,
tail -n +1 $SAMPLEFILE |  sed -n ${N}p | while read STRAIN GENOME
do
    OUTNAME=$STRAIN.self
    GENOMEIDX=$IDX/$(echo -n $GENOME | perl -p -e 's/\.(fna|fasta|fa)//')
    echo "Af293 is ${Af293} and A1163 is ${A1163}"
    FILES=()
    echo $INDIR/${STRAIN}.$FASTQEXT
    if [ -f $INDIR/${STRAIN}.$FASTQEXT ]; then
	FILES=("$INDIR/${STRAIN}.$FASTQEXT")
    elif [ -f $INDIR/${STRAIN}_${FWDEXT}.$FASTQEXT ]; then
	FILES=("$INDIR/${STRAIN}_${FWDEXT}.$FASTQEXT" "$INDIR/${STRAIN}_${REVEXT}.$FASTQEXT")
    else
	echo "cannot find $INDIR/${STRAIN}_${FWDEXT}.$FASTQEXT or $INDIR/${STRAIN}.$FASTQEXT"
	exit
    fi
    echo $OUTDIR/$OUTNAME
    if [ ! -s $OUTDIR/$OUTNAME.Log.progress.out ]; then
      STAR --outSAMstrandField intronMotif --runThreadN $CPU --outMultimapperOrder Random --twopassMode Basic \
	 --genomeDir $GENOMEIDX --outFileNamePrefix $OUTDIR/$OUTNAME. --readFilesCommand zcat \
	 --readFilesIn "${FILES[@]}"
    fi

    OUTNAME=$STRAIN.A1163
    if [ ! -s $OUTDIR/$OUTNAME.Log.progress.out ]; then
      STAR --outSAMstrandField intronMotif --runThreadN $CPU --outMultimapperOrder Random --twopassMode Basic \
	 --genomeDir ${A1163} --outFileNamePrefix $OUTDIR/$OUTNAME. --readFilesCommand zcat \
	 --readFilesIn "${FILES[@]}"
    fi
    OUTNAME=$STRAIN.Af293
    if [ ! -s $OUTDIR/$OUTNAME.Log.progress.out ]; then
      STAR --outSAMstrandField intronMotif --runThreadN $CPU --outMultimapperOrder Random --twopassMode Basic \
	 --genomeDir ${Af293} --outFileNamePrefix $OUTDIR/$OUTNAME. --readFilesCommand zcat \
	 --readFilesIn "${FILES[@]}"
    fi
done
