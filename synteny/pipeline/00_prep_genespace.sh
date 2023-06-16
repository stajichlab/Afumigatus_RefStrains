#!/usr/bin/bash -l
#SBATCH -p short --out logs/prep_genespace.log

module load biopython

mkdir -p peptide cds bed dna gff

# FungiDB sets

curl -C- -o dna/Af293.fasta https://fungidb.org/common/downloads/release-63/AfumigatusAf293/fasta/data/FungiDB-63_AfumigatusAf293_Genome.fasta
curl -C- -o gff/Af293.gff https://fungidb.org/common/downloads/release-63/AfumigatusAf293/gff/data/FungiDB-63_AfumigatusAf293.gff

curl -C- -o dna/A1163.fasta https://fungidb.org/common/downloads/release-63/AfumigatusA1163/fasta/data/FungiDB-63_AfumigatusA1163_Genome.fasta
curl -C- -o gff/A1163.gff https://fungidb.org/common/downloads/release-63/AfumigatusA1163/gff/data/FungiDB-63_AfumigatusA1163.gff


# loops would have been smart here but oh well
if [ ! -s peptide/Af293.fa ]; then
    curl https://fungidb.org/common/downloads/release-63/AfumigatusAf293/fasta/data/FungiDB-63_AfumigatusAf293_AnnotatedProteins.fasta |
	perl -p -e 's/>(\S+).+gene=(\S+)\s+.+/>$1 $2/' | ./scripts/get_longest.py > peptide/Af293.fa
fi

if [ ! -s peptide/A1163.fa ]; then
    curl https://fungidb.org/common/downloads/release-63/AfumigatusA1163/fasta/data/FungiDB-63_AfumigatusA1163_AnnotatedProteins.fasta |
	perl -p -e 's/>(\S+).+gene=(\S+)\s+.+/>$1 $2/' | ./scripts/get_longest.py > peptide/A1163.fa
fi


# these require special treatment as the LOCUS name was not the primary name in these FungiDB files
perl -i -p -e 's/>\S+\s+(\S+)/>$1/' peptide/Af293.fa peptide/A1163.fa


for name in Af293 A1163
do
    if [ ! -s bed/$name.bed ]; then
	grep  -P "\tprotein_coding_gene\t" gff/$name.gff | cut -f 1,4,5,9 | perl -p -e 's/ID=([^;]+);.+/$1/' > bed/$name.bed
    fi
done

# our local annotation
SOURCE=../annotation

for STRAIN in $(ls $SOURCE)
do

    GFF=$(ls $SOURCE/$STRAIN/annotate_results/*.gff3)
    DIR=$(dirname $GFF)
    PREF=$(echo -n $STRAIN | perl -p -e 's/Aspergillus_fumigatus_//; s/\.gff3//')
    cp $GFF gff/$PREF.gff
    cp $DIR/$PREF.scaffolds.fa dna/$PREF.fasta
    grep -P "\tmRNA\t" $GFF |  cut -f 1,4,5,9 | perl -p -e 's/ID=([^\;]+);.+/$1/' > bed/$PREF.bed
    # take first isoform for simplicity
    cat $DIR/$PREF.cds-transcripts.fa | ./scripts/get_longest.py > cds/$PREF.fa
    cat $DIR/$PREF.proteins.fa | ./scripts/get_longest.py > peptide/$PREF.fa
    perl -i -p -e 's/>(\S+).+/>$1/' peptide/$PREF.fa
done
