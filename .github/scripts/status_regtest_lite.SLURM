#!/bin/bash
# Required environment variables: $HOME_DIR, $OWNER, $PATH, $PUSH_LOGS, $REPO, $SHA, $STATUS
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

if [[ $PUSH_LOGS==true ]]
then
    export _WD=$PWD
    export GIT_REPO_DIR="${HOME_DIR}/logs/${SHA}"
    cd "${GIT_REPO_DIR}"
    source "${HOME_DIR}/C-PAC_slurm_testing/.github/scripts/wait_for_git_lock.sh"
    wait_for_git_lock
    git add launch/error.log launch/out.log
    wait_for_git_lock
    git commit -m "Add logs for ${PIPELINE} ${DATA} ${SHA}"
    cd $_WD
fi

gh workflow run 'Run launch status update' -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F status="${STATUS}"
