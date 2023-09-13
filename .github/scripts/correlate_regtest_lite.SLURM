#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $PIPELINE $PUSH_LOGS $DATA
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

exec 2>> "${HOME_DIR}/logs/${SHA}/debug.log"
set -x

if [[ PUSH_LOGS==true ]]
then
    export _WD=$PWD
    export GIT_REPO_DIR="${HOME_DIR}/logs/${SHA}"
    cd "${GIT_REPO_DIR}"
    source "${HOME_DIR}/slurm_testing_callback/.github/scripts/wait_for_git_lock.sh"
    wait_for_git_lock
    git add slurm-${PIPELINE}-${DATA}
    wait_for_git_lock
    git commit -m "Add logs for ${PIPELINE} ${DATA} ${SHA}"
    cd $_WD
fi

gh workflow run 'Correlate Regression Test' -F ref="$SHA" -F pipeline1='one' -F pipeline2='two' -F repo="$REPO" -F owner="$OWNER" -F preconfig="$PIPELINE" -F data_source="$DATA"
