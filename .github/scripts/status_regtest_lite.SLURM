#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $STATUS
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

gh workflow run 'Run launch status update' -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F status="${STATUS}" -F log_output=$(cat "${HOME_DIR}/logs/${SHA}/out.log") -F log_error=$(cat "${HOME_DIR}/logs/${SHA}/error.log")

