set -xv
set -o pipefail

#empty trash
hadoop fs -expunge

export MODEL_PATH=$1
export queue_name=$2

hadoop fs -cat ${MODEL_PATH}/*.csv > mapping.csv
hadoop fs -rm ${MODEL_PATH}/*.csv
hadoop fs -put mapping.csv ${MODEL_PATH}/


