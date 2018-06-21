set -xv
set -o pipefail

#empty trash
#hadoop fs -expunge

#Clear Model landing zone
export TRAIN_INPUT_DIR=$1
export queue_name=$2
export MODEL_PATH=$3
export REL_DATE=$4


# Delete output file
hadoop fs -rm -f -r -skipTrash ${MODEL_PATH}
hadoop fs -mkdir ${MODEL_PATH}
hadoop fs -rm -r -skipTrash ${TRAIN_INPUT_DIR}/noout



# run streaming model training in R
hadoop jar /usr/hdp/current/hadoop-mapreduce-client/hadoop-streaming.jar \
-Dmapreduce.job.queuename=${queue_name} \
-Dmapreduce.task.timeout=0 \
-file arimax_training_mapper.R \
-file arimax_training_reducer.R \
-mapper "arimax_training_mapper.R" \
-reducer "arimax_training_reducer.R $REL_DATE ${MODEL_PATH}" \
-input ${TRAIN_INPUT_DIR} \
-output ${TRAIN_INPUT_DIR}/noout \
-numReduceTasks 1000 \


