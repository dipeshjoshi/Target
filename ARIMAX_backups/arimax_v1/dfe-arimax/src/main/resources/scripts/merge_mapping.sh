set -xv
set -o pipefail

#empty trash
hadoop fs -expunge

export MODEL_PATH=$1
export queue_name=$2
export rel_date=$3

hadoop fs -cat ${MODEL_PATH}/$rel_date/*.csv > mapping.csv
hadoop fs -rm ${MODEL_PATH}/$rel_date/*.csv
hadoop fs -put mapping.csv ${MODEL_PATH}/$rel_date/


