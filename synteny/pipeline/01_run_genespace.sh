#!/usr/bin/bash -l
#SBATCH -p short -c 48 --mem 128gb -N 1 -n 1 --out logs/genespace_run.%A.log
module load orthofinder
module load MCScanX
module load R

Rscript scripts/genespace.R

