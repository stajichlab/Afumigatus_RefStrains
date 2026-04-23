#!/usr/bin/bash -l
#SBATCH -p short --mem 8gb -N 1 -n 1 -c 8 --out logs/jbrowse_setup.log
CPU=8
module load jbrowse2
module load minimap2
module load samtools
module load bcftools
module load genometools

mkdir -p jbrowse2
DIR=$(realpath jbrowse2)
jbrowse create $DIR

pushd dna
for a in $(ls *.fasta); do
	if [ ! -f $a.gz ]; then
		bgzip --keep $a
	fi
	if [ ! -f $a.gz.fai ]; then
		samtools faidx $a.gz
	fi
	jbrowse add-assembly $a.gz --load copy --out $DIR
done

for g1 in $(ls *.fasta)
do
	g1name=$(basename $g1 .fasta)
	for g2 in $(ls *.fasta | grep -v $g1)
	do
		g2name=$(basename $g2 .fasta)
		SYNTENY=${g1name}_vs_${g2name}.paf
		if [ ! -s $SYNTENY ]; then
			minimap2 -t $CPU -x asm20 $g1 $g2 > $SYNTENY
		fi
		# If minimap2 is run as minimap2 grape.fa peach.fa, then you need to load as --assemblyNames peach,grape.
		jbrowse add-track ${g1name}_vs_${g2name}.paf --assemblyNames $g2name,$g1name --load copy --out $DIR
	done
done
popd

mkdir -p gff_sorted
pushd gff
for a in $(ls *.gff); do
	name=$(basename $a .gff)
	perl -i -p -e 's/(cutsit|prob|cutsite)=/$1__/g' $a
	perl -i -p -e 's/EC_number/ec_number/g' $a
	gt gff3 -sortlines -tidy -retainids $a > ../gff_sorted/$a
	bgzip -f ../gff_sorted/$a
	tabix -f ../gff_sorted/$a.gz
	jbrowse add-track ../gff_sorted/$a.gz --assemblyNames $name --load copy --out $DIR
done
popd

jbrowse text-index --out $DIR
tar cf $DIR.tar $(dirname $DIR)
pigz $DIR.tar
