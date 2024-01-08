#!/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

# Required environment variables: $DATA, $HOME_DIR, $OWNER, $PATH, $PIPELINE, $PUSH_LOGS, $REPO, $SHA

if [[ $PUSH_LOGS==true ]]
then
    export _WD=$PWD
    export GIT_REPO_DIR="${HOME_DIR}/logs/${SHA}"
    cd "${GIT_REPO_DIR}"
    source "${HOME_DIR}/C-PAC_slurm_testing/.github/scripts/wait_for_git_lock.sh"
    wait_for_git_lock
    git add slurm-${PIPELINE}-${DATA}
    wait_for_git_lock
    git commit -m "Add logs for ${PIPELINE} ${DATA} ${SHA}"
    cd $_WD
fi

gh workflow run "Test run failed" -F ref="$SHA" -F owner="$OWNER" -F repo="$REPO" -F preconfig="$PIPELINE" -F data_source="$DATA"
