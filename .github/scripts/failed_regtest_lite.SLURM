#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $PIPELINE $DATA
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

gh workflow run 'Test run failed' -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F log_output=$(cat "${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}.out") -F log_error=$(cat "${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}.err") -F preconfig="$PIPELINE" -F data_source="$DATA"
