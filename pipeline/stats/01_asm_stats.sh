#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 2 --mem 4gb --out logs/assess.log

module load AAFTF

IFS=,
SAMPLES=samples.csv
INDIR=asm
OUTDIR=genomes

mkdir -p $OUTDIR
while read STRAIN NANOPORE ILLUMINA
do
    rsync -a $INDIR/canu/$STRAIN/$STRAIN.contigs.fasta $OUTDIR/$STRAIN.canu.fasta
    rsync -a $INDIR/flye/$STRAIN/assembly.fasta $OUTDIR/$STRAIN.flye.fasta
    for type in canu flye
    do
	if [[ -s $OUTDIR/$STRAIN.$type.fasta ]]; then
		if [[ ! -f $OUTDIR/$STRAIN.$type.stats.txt || $OUTDIR/$STRAIN.$type.fasta -nt $OUTDIR/$STRAIN.$type.stats.txt ]]; then
			AAFTF assess -i $OUTDIR/$STRAIN.$type.fasta -r $OUTDIR/$STRAIN.$type.stats.txt
		fi
	fi
    done    
done < $SAMPLES


