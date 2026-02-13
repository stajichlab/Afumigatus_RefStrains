#!/usr/bin/bash -l
#SBATCH -p short -c  2 --mem 2gb -N 1 -n 1 

module load ncbi-table2asn
mv *.fa $(basename `ls *.fa` .scaffolds.fa).fsa
table2asn -l paired-ends -V v -M n -c ef -i *.fsa -o Aspergillus_fumigatus_CEA10.sqn -Z -t ../../../lib/sbt/Afum.sbt  -euk  -j "[organism=Aspergillus fumigatus] [strain=CEA10] [gcode=1]"
