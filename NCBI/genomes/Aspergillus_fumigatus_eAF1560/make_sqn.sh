#!/usr/bin/bash -l
#SBATCH -p short -c  2 --mem 2gb -N 1 -n 1 

module load ncbi-table2asn
NAME=$(basename `pwd`)
if [ ! -s $NAME.fsa ]; then
 mv *.fa $NAME.fsa
fi

table2asn -l paired-ends -V v -M n -c ef -i $NAME.fsa -o $NAME.sqn -Z -euk -t ../../../lib/sbt/Afum.sbt -j "[organism=Aspergillus fumigatus] [strain=eAF1560] [gcode=1]"
