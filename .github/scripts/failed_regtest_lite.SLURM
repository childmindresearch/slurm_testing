#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $PIPELINE $DATA
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

exec 2> "${HOME_DIR}/debug.log"
set -x

export _WD=$PWD
PUSH_LOGS=true
cd "${HOME_DIR}/logs/${SHA}" || PUSH_LOGS=false
if [[ PUSH_LOGS == true ]]
then
    git remote add origin git@github.com:shnizzedy/regtest-runlogs.git
    git switch -c $REPO_$SHA
    git add slurm-${PIPELINE}-${DATA}.*
    git commit -m "Add logs for ${PIPELINE} ${DATA} ${SHA}"
    git push origin $REPO_$SHA || true
    cd $_WD
fi

gh workflow run 'Test run failed' -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F preconfig="$PIPELINE" -F data_source="$DATA"
