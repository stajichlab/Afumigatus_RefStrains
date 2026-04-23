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
tar cf $OUT.tar $OUT
pigz $OUT.tar
