#!/usr/bin/env bash

#PBS -W group_list=bhurwitz
#PBS -q qualified
#PBS -l select=1:ncpus=6:mem=11gb
#PBS -l walltime=24:00:00
#PBS -l cput=24:00:00
#PBS -M scottdaniel@email.arizona.edu
#PBS -m bea

COMMON="$WORKER_DIR/common.sh"

if [ -e $COMMON ]; then
  . "$COMMON"
else
  echo Missing common \"$COMMON\"
  exit 1
fi

set -u

echo "Started at $(date) on host $(hostname)"

LEFT_TMP_FILES=$(mktemp)
#RIGHT_TMP_FILES=$(mktemp)

get_lines $LEFT_FILES_LIST $LEFT_TMP_FILES $FILE_START $STEP_SIZE
#get_lines $RIGHT_FILES_LIST $RIGHT_TMP_FILES $FILE_START $STEP_SIZE
#Just check through the whole right_files_list

NUM_FILES=$(lc $LEFT_TMP_FILES)

echo Found \"$NUM_FILES\" files to process
echo Processing $(cat $LEFT_TMP_FILES) and $(cat $RIGHT_TMP_FILES)

while read LEFT_FASTQ; do

    while read RIGHT_FASTQ; do

        test2=$(echo $RIGHT_FASTQ | sed s/_R[1-2]//)
        test1=$(echo $LEFT_FASTQ | sed s/_R[1-2]//)

        if [ "$test1" = "$test2" ]; then
            IN_LEFT=$FILTERED_DIR/$LEFT_FASTQ
            IN_RIGHT=$FILTERED_DIR/$RIGHT_FASTQ
           
            NEWNAME=$(echo $LEFT_FASTQ | sed s/_R[1,2]//)

            OUT=$SORTNMG_DIR/$(basename $NEWNAME ".fastq.trimmed.clipped")
            
            if [[ -e "$OUT".1.fastq ]]; then
                echo "Merged file already exists, skipping..."
                continue
            else
                echo "Processing $LEFT_FASTQ and $RIGHT_FASTQ"
            fi

            perl $WORKER_DIR/mergeShuffledFastqSeqs.pl \
                -f1 $IN_LEFT \
                -f2 $IN_RIGHT \
                -r '^@(\S+)\s[1|2]\S+$' \
                -o $OUT \
                -t

        else
            echo Could not find a match for "$LEFT_FASTQ"
            continue
        fi

        done < "$RIGHT_FILE_LIST"

done < "$LEFT_TMP_FILES"

echo "Done at $(date)"
