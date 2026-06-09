#!/usr/bin/bash -l
#SBATCH -p short -c 4 --mem 8gb

module load kallisto

for a in $(ls cds/*.cds.fa); do kallisto index -i kallisto_index/$(basename $a .cds.fa).idx $a --make-unique; done
