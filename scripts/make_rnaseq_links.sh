#!/usr/bin/bash -l
#SBATCH -p short
KEY=lib/RNASeq_sample_key.tsv
TARGET=lib/RNASeq
SRC=/bigdata/stajichlab/shared/projects/SeqData/Cramer/Afumigatus/RNASeq/StrainHeterogenity_2021-05/
mkdir -p $TARGET
grep -v ^# $KEY | while read NUM ID; do 
    if [ ! -d $TARGET/$ID ]; then 
	echo $ID; mkdir -p $TARGET/$ID;
	ln -s $SRC/run?/${NUM}[NH]* $TARGET/$ID/
    fi
    if [ ! -f $TARGET/$ID.fastq.gz ]; then
	cat $TARGET/$ID/*.gz > $TARGET/$ID.fastq.gz
    fi
done

