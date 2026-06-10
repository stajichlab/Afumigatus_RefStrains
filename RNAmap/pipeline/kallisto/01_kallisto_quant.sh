#!/usr/bin/bash
#SBATCH --mem 16gb -N 1 -c 8 -n 1 --out logs/kallisto_quant.log

module load kallisto

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

OUTDIR=results/kallisto
IDXDIR=kallisto_index
INDIR=fastq
SAMPLEFILE=samples_kallisto.csv
FASTQEXT=fastq.gz
FWDEXT=R1
REVEXT=R2

# Fragment length parameters for single-end libraries (adjust per library prep)
FRAG_LEN=200
FRAG_SD=20

# Reference indices to also map against
REF_Af293=${IDXDIR}/Af293.idx
REF_CEA10=${IDXDIR}/CEA10.idx

IFS=,
tail -n +2 $SAMPLEFILE | while read STRAIN INDEX
do
    SELFIDX=${IDXDIR}/${INDEX}.idx
    if [ ! -f "$SELFIDX" ]; then
        echo "ERROR: index not found: $SELFIDX"
        exit 1
    fi

    # Detect single-end vs paired-end
    PAIRED=0
    FILES=()
    if [ -f "${INDIR}/${STRAIN}_${FWDEXT}.${FASTQEXT}" ]; then
        FILES=("${INDIR}/${STRAIN}_${FWDEXT}.${FASTQEXT}" "${INDIR}/${STRAIN}_${REVEXT}.${FASTQEXT}")
        PAIRED=1
    elif [ -f "${INDIR}/${STRAIN}.${FASTQEXT}" ]; then
        FILES=("${INDIR}/${STRAIN}.${FASTQEXT}")
    else
        echo "ERROR: cannot find fastq for $STRAIN in $INDIR"
        exit 1
    fi

    build_quant_args() {
        local IDX=$1
        local OUTNAME=$2
        mkdir -p ${OUTDIR}/${OUTNAME}
        if [ ! -f "${OUTDIR}/${OUTNAME}/run_info.json" ]; then
            if [ $PAIRED -eq 1 ]; then
                kallisto quant -i $IDX -o ${OUTDIR}/${OUTNAME} -t $CPU \
                    "${FILES[@]}"
            else
                kallisto quant -i $IDX -o ${OUTDIR}/${OUTNAME} -t $CPU \
                    --single -l $FRAG_LEN -s $FRAG_SD \
                    "${FILES[@]}"
            fi
        else
            echo "Skipping ${OUTNAME}: already complete"
        fi
    }

    # Map against own CDS index
    build_quant_args "$SELFIDX" "${STRAIN}.self"

    # Map against Af293 reference
    if [ -f "$REF_Af293" ]; then
        build_quant_args "$REF_Af293" "${STRAIN}.Af293"
    fi

    # Map against CEA10 (A1163) reference
    if [ -f "$REF_CEA10" ]; then
        build_quant_args "$REF_CEA10" "${STRAIN}.CEA10"
    fi

done
