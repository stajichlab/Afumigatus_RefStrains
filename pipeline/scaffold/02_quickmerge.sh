#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 4  --mem 64gb --out logs/quickmerge.%a.log -a 1

module load quickmerge
module load mummer/4.0.0

N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
	echo "no value for SLURM ARRAY - specify with -a or cmdline"
    fi
fi

CPU=$SLURM_CPUS_ON_NODE
if [ -z $CPU ]; then
	CPU=1
fi


IFS=,
SAMPLES=samples.csv
INDIR=genomes
OUTDIR=asm/quick_merge
AF293=ref_genomes/FungiDB-56_AfumigatusAf293_Genome.fasta
A1163=ref_genomes/FungiDB-56_AfumigatusA1163_Genome.fasta
mkdir -p $OUTDIR
sed -n ${N}p $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do
   echo "line is $STRAIN $NANOPORE"

   mkdir -p $OUTDIR/$STRAIN
   CANU=$(realpath $INDIR/$STRAIN.canu.pilon.fasta)
   FLYE=$(realpath $INDIR/$STRAIN.flye.pilon.fasta)
   pushd $OUTDIR/$STRAIN
   merge_wrapper.py -l 100 --threads $CPU --version4 --ml 2000000 --prefix ${STRAIN}_flye_canu $FLYE $CANU
   popd
   merge_wrapper.py -l 100 --threads $CPU --version4 --ml 2000000 --prefix round2 ${STRAIN}_flye_canu.merged_out.fasta $FLYE
   popd
done
