#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 4  --mem 4gb --out logs/ragtag_scaffold.log

module load ragtag
CPUS=$SLURM_CPUS_ON_NODE
if [ -z $CPUS ]; then
 CPUS=1
fi


IFS=,
SAMPLES=samples.csv
INDIR=genomes
OUTDIR=asm/ref_scaffold
AF293=ref_genomes/FungiDB-56_AfumigatusAf293_Genome.fasta
A1163=ref_genomes/FungiDB-56_AfumigatusA1163_Genome.fasta
mkdir -p $OUTDIR
cat $SAMPLES | while read STRAIN NANOPORE ILLUMINA LOCUS
do
	# skip flye for now
    for type in canu 
    do
	if [ ! -f $INDIR/$STRAIN.$type.pilon.fasta ]; then
		echo "Cannot find $INDIR/$STRAIN.$type.pilon.fasta"
		exit
	fi
	echo "out=>$OUTDIR/$STRAIN.$type.A1163 ref=$A1163 in=$INDIR/$STRAIN.$type.pilon.fasta"

	#ragtag.py scaffold -t $CPUS -o $OUTDIR/$STRAIN.$type.A1163 $A1163 $INDIR/$STRAIN.$type.pilon.fasta
	ragtag.py scaffold -t $CPUS -o $OUTDIR/$STRAIN.$type.AF293 $AF293 $INDIR/$STRAIN.$type.pilon.fasta
    done
done

