#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $IMAGE_NAME $PIPELINE $DATA
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

gh workflow run "Test run failed" -F log_error=$(cat ${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}-${IMAGE_NAME}.err) -F log_output=$(cat ${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}-${IMAGE_NAME}.out) -F ref="$SHA" -F owner="$OWNER" -F repo="$REPO" -F preconfig="$PIPELINE" -F data_source="$DATA"
