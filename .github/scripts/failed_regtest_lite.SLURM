#!/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks=1

# Required environment variables: $DATA, $HOME_DIR, $OWNER, $PATH, $PIPELINE, $PUSH_LOGS, $REPO, $SHA

if [[ $PUSH_LOGS == true ]]
then
    # shellcheck disable=SC1090
    source "${TOKEN_FILE}"
    export _WD=$PWD
    export GIT_REPO_DIR="${HOME_DIR}/logs/${SHA}"
    cd "${GIT_REPO_DIR}" || exit 1
    # shellcheck disable=SC1090
    source "${HOME_DIR}/C-PAC_slurm_testing/.github/scripts/wait_for_git_lock.sh"
    wait_for_git_lock
    git add "slurm-${PIPELINE}-${DATA}"
    wait_for_git_lock
    git commit -m "Add logs for ${PIPELINE} ${DATA} ${SHA}"
    cd "$_WD" || exit 1
fi
export _CPAC_STATUS_DATA_SOURCE="${DATA}"
export _CPAC_STATUS_PRECONFIG="${PIPELINE}"
export _CPAC_STATUS_SUBJECT="${SUBJECT}"
export _CPAC_STATUS_STATE=failed
# "${HOME_DIR}/C-PAC_slurm_testing/.github/scripts/status.py"
