#!/usr/bin/bash -l
#SBATCH -p short -c 4 --mem 16gb --out logs/liftoff.log

module load workspace/scratch
CPU=4
REFASMTSV=lib/ref_assemblies.tsv
INGENOME=genome
OUTDIR=results/liftoff
REFFA=gff3/FungiDB-56_AfumigatusAf293_Genome.fasta
REFGFF=gff3/FungiDB-56_AfumigatusAf293.gff
STEM=$(basename "$REFGFF" .gff)
mkdir -p $OUTDIR

for FA in $INGENOME/*.fna
do
	NAME=$(basename "$FA" .fna)
	STRAIN=$(grep "$NAME" "$REFASMTSV" | cut -f3)
	if [[ -z "$STRAIN" ]]; then echo "ERROR: no strain found for $NAME"; exit 1; fi
# for testing keep off
	pixi run \
		liftoff -g $REFGFF \
		-o $OUTDIR/${NAME}.$STEM.gff \
		-u $OUTDIR/${NAME}.$STEM.unmapped \
		-dir $SCRATCH/${NAME}_$STEM -p $CPU \
		"$FA" "$REFFA" 
	perl -i.bak -p -e "s/(Parent|gene_id|ID)=([^;]+)(;|\$)/\$1=${STRAIN}.\$2\$3/g;" \
    "$OUTDIR/${NAME}.$STEM.gff"
#	break # testing
done

REFFA=gff3/FungiDB-56_AfumigatusA1163_Genome.fasta
REFGFF=gff3/FungiDB-56_AfumigatusA1163.gff
STEM=$(basename "$REFGFF" .gff)
for FA in $INGENOME/*.fna
do
	NAME=$(basename "$FA" .fna)
	STRAIN=$(grep "$NAME" "$REFASMTSV" | cut -f3)
	if [[ -z "$STRAIN" ]]; then echo "ERROR: no strain found for $NAME in $REFASMTSV"; exit 1; fi
# for testing keep off
	pixi run \
		liftoff -g $REFGFF \
		-o $OUTDIR/${NAME}.$STEM.gff \
		-u $OUTDIR/${NAME}.$STEM.unmapped \
		-dir $SCRATCH/${NAME}_$STEM -p $CPU \
		"$FA" "$REFFA" 
	perl -i.bak -p -e "s/(Parent|Name|gene_id|ID)=([^;]+)(;|\$)/\$1=${STRAIN}.\$2\$3/g;" \
    "$OUTDIR/${NAME}.$STEM.gff"
	
#	break # testing
done

