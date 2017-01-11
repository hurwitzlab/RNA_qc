#!/bin/bash

# --------------------------------------------------
# 00-qc-fastq.sh
#
# This script runs illumina QC on a directory
# of fastq files, runs the paired read analysis,
# trims and then discards reads that are too short
# or too low quality
# For example:
# paired reads are in separate files:
# RNA_1_ACAGTG_L008_R1_001.fastq
# RNA_1_ACAGTG_L008_R2_001.fastq
#
# --------------------------------------------------

set -u
source ./config.sh
export CWD="$PWD"
export STEP_SIZE=20

PROG=$(basename $0 ".sh")
STDOUT_DIR="$CWD/out/$PROG"

init_dir "$STDOUT_DIR"

if [[ ! -d $RAW_DIR ]]; then
  echo "Bad RAW_DIR ($RAW_DIR)"
  exit 0
fi

if [[ ! -d $FILTERED_DIR ]]; then
  mkdir -p $FILTERED_DIR
fi

echo RAW_DIR \"$RAW_DIR\"

export FILES_LIST="./$PROG.in"

#
# find those RNA files!
#
find $RAW_DIR -name \*RNA\* > $FILES_LIST

NUM_FILES=$(lc $FILES_LIST)

echo Found \"$NUM_FILES\" input files

if [[ $NUM_FILES -lt 1 ]]; then
  echo Nothing to do.
  exit 1
fi

JOB=$(qsub -J 1-$NUM_FILES:$STEP_SIZE -V -N qc_fastq -j oe -o "$STDOUT_DIR" $SCRIPT_DIR/qc_fastq.sh)

if [[ $? -eq 0 ]]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" Sayonara.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
