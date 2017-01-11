set -u
source ./config.sh

cd "$FILTERED_DIR"

export LEFT_FILES_LIST="$PRJ_DIR/left_fastqs"
export RIGHT_FILES_LIST="$PRJ_DIR/right_fastqs"

echo "Finding fastq's"

find . -type f -iname \*R1\*clipped | sed "s/^\.\///" | sort > $LEFT_FILES_LIST 
find . -type f -iname \*R2\*clipped | sed "s/^\.\///" | sort > $RIGHT_FILES_LIST 

echo "Checking if orphaned"

export ORPHAN_LIST="$PRJ_DIR/orphan-list"

if [ -e $ORPHAN_LIST ]; then
    rm $ORPHAN_LIST
fi

NEWRIGHTLIST=$(mktemp)
cat $RIGHT_FILES_LIST | sed s/_R[1,2]// > $NEWRIGHTLIST

while read FASTQ; do

    NEWNAME=$(echo $FASTQ | sed s/_R[1,2]//)
    FOUND=$(egrep $NEWNAME $NEWRIGHTLIST)

    if [[ -z "$FOUND" ]]; then
        echo "$FASTQ" is an orphan
        echo "$FASTQ" >> $ORPHAN_LIST
    else
        echo "$FASTQ" is not an orphan
        continue
    fi

done < $LEFT_FILES_LIST

NEWLEFTLIST=$(mktemp)
cat $LEFT_FILES_LIST | sed s/_R[1,2]// > $NEWLEFTLIST

while read FASTQ; do

    NEWNAME=$(echo $FASTQ | sed s/_R[1,2]//)
    FOUND=$(egrep $NEWNAME $NEWLEFTLIST)

    if [[ -z "$FOUND" ]]; then
        echo "$FASTQ" is an orphan
        echo "$FASTQ" >> $ORPHAN_LIST
    else
        echo "$FASTQ" is not an orphan
        continue
    fi

done < $RIGHT_FILES_LIST


