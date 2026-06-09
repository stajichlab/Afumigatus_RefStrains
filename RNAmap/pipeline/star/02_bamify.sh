#!/usr/bin/bash -l
#SBATCH -p epyc -c 24 -N 1 -n 1 --mem 64gb --out logs/make_bam.log

CPU=8
module load samtools
FOLDER=results/STAR
parallel -j 6 samtools view --threads $CPU -O BAM -o {.}.unsort.bam {} ::: $(find $FOLDER -name "*.sam")
for file in $(find $FOLDER -name "*.unsort.bam")
do
	OUT=$(basename $file .unsort.bam)
	if [ ! -f $FOLDER/$OUT.bam.csi ]; then
		samtools sort -T $SCRATCH/$OUT --threads $CPU --write-index -o $FOLDER/$OUT.bam $file
	fi
done
