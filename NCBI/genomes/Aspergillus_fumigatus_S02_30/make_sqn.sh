#!/usr/bin/bash -l
#SBATCH -p short -c  2 --mem 2gb -N 1 -n 1 

module load ncbi-table2asn
table2asn -l paired-ends -V v -M n -c ef -i *.fsa -o Aspergillus_fumigatus_S02_30.sqn -Z -t ../../../lib/sbt/Afum.sbt  -euk  -j "[organism=Aspergillus fumigatus] [strain=08-19-02-30] [gcode=1]"
