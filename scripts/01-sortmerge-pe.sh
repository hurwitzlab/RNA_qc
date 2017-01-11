#!/usr/bin/env bash

#
# This script is intended to go through two paired read files and make sure there are matching reads
# Any unmatching are outputted into a seperate file
#

set -u
source ./config.sh
export CWD="$PWD"
export STEP_SIZE=10

PROG=`basename $0 ".sh"`
#Just going to put stdout and stderr together into stdout
STDOUT_DIR="$CWD/out/$PROG"

init_dir "$STDOUT_DIR"

if [[ -d "$SORTNMG_DIR" ]]; then
    echo "Continuing where you left off..."
else
    mkdir -p "$SORTNMG_DIR"
fi

cd "$FILTERED_FQ"

export LEFT_FILES_LIST="$PRJ_DIR/left_fastqs"
export RIGHT_FILES_LIST="$PRJ_DIR/right_fastqs"

echo "Finding fastq's"

find . -type f -iname \*R1\*.fastq | sed "s/^\.\///" | sort > $LEFT_FILES_LIST 
find . -type f -iname \*R2\*.fastq | sed "s/^\.\///" | sort > $RIGHT_FILES_LIST 

echo "Checking if already processed"

if [ -e $PRJ_DIR/files-to-process ]; then
    rm $PRJ_DIR/files-to-process
fi

export FILES_TO_PROCESS="$PRJ_DIR/files-to-process"

while read FASTQ; do
 
    NEWNAME=$(echo $FASTQ | sed s/_R[1,2]//)

    OUT=$SORTNMG_DIR/$(basename $NEWNAME ".filtered.fastq").1.fastq

    if [[ -e $OUT ]]; then
        continue
    else
        echo $FASTQ >> $FILES_TO_PROCESS
    fi

done < $LEFT_FILES_LIST

NUM_FILES=$(lc $FILES_TO_PROCESS)

echo \"Found $NUM_FILES to process\"

echo \"Splitting them up in batches of "$STEP_SIZE"\"

let i=1

while (( "$i" <= "$NUM_FILES" )); do
    export FILE_START=$i
    echo Doing file $i plus 9 more if possible
    JOB=$(qsub -V -N merge-fq -j oe -o "$STDOUT_DIR" $WORKER_DIR/run-merge-fq.sh)
    if [ $? -eq 0 ]; then
      echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Remember: time you enjoy wasting is not wasted time.
    else
      echo -e "\nError submitting job\n$JOB\n"
    fi
    (( i += $STEP_SIZE )) 
done
