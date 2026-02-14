#!/usr/bin/bash -l
#SBATCH -p short -c  2 --mem 2gb -N 1 -n 1  -C cascade

module load ncbi-table2asn
NAME=$(basename `pwd`)

if [ ! -s $NAME.fsa ]; then
 mv $NAME.fa $NAME.fsa
fi

table2asn -l paired-ends -V v -M n -c ef -i $NAME.fsa -o $NAME.sqn -Z -euk -t ../../../lib/sbt/Afum.sbt -j "[organism=Aspergillus fumigatus] [strain=eAF1090] [gcode=1]"
