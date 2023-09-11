#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $PIPELINE $DATA
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

exec 2> "${HOME_DIR}/logs/${SHA}/debug.log"
set -x

if [[ PUSH_LOGS==true ]]
then
    export _WD=$PWD
    cd "${HOME_DIR}/logs/${SHA}"
    git add slurm-${PIPELINE}-${DATA}
    git commit -m "Add logs for ${PIPELINE} ${DATA} ${SHA}"
    cd $_WD
fi

gh workflow run 'Test run failed' -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F preconfig="$PIPELINE" -F data_source="$DATA"
