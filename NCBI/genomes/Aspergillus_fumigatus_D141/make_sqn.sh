#!/usr/bin/bash -l
#SBATCH -p short -c  2 --mem 2gb -N 1 -n 1 

module load ncbi-table2asn
if [ -z $(ls *.fsa) ]; then
	mv *.fa $(basename `ls *.fa` .scaffolds.fa).fsa
fi
table2asn -l paired-ends -V v -M n -c ef -i *.fsa -o Aspergillus_fumigatus_D141.sqn -Z -t ../../../lib/sbt/Afum.sbt  -euk  -j "[organism=Aspergillus fumigatus] [strain=D141] [gcode=1]"
