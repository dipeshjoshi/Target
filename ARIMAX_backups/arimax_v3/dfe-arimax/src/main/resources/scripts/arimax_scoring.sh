set -xv
set -o pipefail

#empty trash
#hadoop fs -expunge

export SCORE_INPUT_DIR=$1
export SCORE_OUTPUT_DIR=$2
export queue_name=$3
export LATEST_MODEL_PATH=$4/arimax_models
export REL_DATE=$5
export HORIZON=$6

# Delete output file
hadoop fs -rm -f -r -skipTrash ${SCORE_OUTPUT_DIR}


# run streaming model training in R
hadoop jar /usr/hdp/current/hadoop-mapreduce-client/hadoop-streaming.jar \
-Dmapreduce.task.timeout=0 \
-file arimax_training_mapper.R \
-file arimax_scoring_reducer.R \
-mapper "arimax_training_mapper.R" \
-reducer "arimax_scoring_reducer.R $HORIZON $REL_DATE ${LATEST_MODEL_PATH}" \
-input ${SCORE_INPUT_DIR} \
-output ${SCORE_OUTPUT_DIR} \
-numReduceTasks 400 \


