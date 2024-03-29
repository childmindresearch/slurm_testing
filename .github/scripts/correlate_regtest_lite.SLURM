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
    source "${HOME_DIR}/slurm_testing/.github/scripts/wait_for_git_lock.sh"
    wait_for_git_lock
    git add slurm-${PIPELINE}-${DATA}
    wait_for_git_lock
    git commit -m "Add logs for ${PIPELINE} ${DATA} ${SHA}"
    cd $_WD
fi

# gh workflow run 'Correlate Regression Test' -F ref="$SHA" -F pipeline1='one' -F pipeline2='two' -F repo="$REPO" -F owner="$OWNER" -F preconfig="$PIPELINE" -F data_source="$DATA"

gh workflow run "Initiate check" -F task="correlate" -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F job="${PIPELINE}-${DATA}-${IMAGE_NAME}" -F preconfig="$PIPELINE" -F data_source="$DATA" || echo "Correlate ${PIPELINE}-${DATA}-${IMAGE_NAME} initiated"

export GITHUB_WORKSPACE="${HOME_DIR}/${IMAGE_NAME}"

python3 reg-suite/main.py correlate --pipeline1 ${GITHUB_WORKSPACE}/${PIPELINE}/${DATA} --pipeline2 ${GITHUB_WORKSPACE}/lite/${PIPELINE}/${DATA} --workspace $GITHUB_WORKSPACE