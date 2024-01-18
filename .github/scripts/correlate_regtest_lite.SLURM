#!/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

# Required environment variables: $COMPARISON_PATH, $DATA, $HOME_DIR, $OWNER, $PATH, $PIPELINE, $PUSH_LOGS, $REPO, $SHA, $TOKEN_FILE

set -x

# shellcheck disable=SC1090
source "${TOKEN_FILE}"

set -x

if [[ $PUSH_LOGS == true ]]
then
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

"${HOME_DIR}/C-PAC_slurm_testing/.github/scripts/status.py" "${DATA}" "${PIPELINE}" "${SUBJECT}" success
# gh workflow run 'Correlate Regression Test' -F ref="$SHA" -F pipeline1='one' -F pipeline2='two' -F repo="$REPO" -F owner="$OWNER" -F preconfig="$PIPELINE" -F data_source="$DATA"

gh workflow run "Initiate check" -F task="correlate" -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F job="${PIPELINE}-${DATA}-${IMAGE_NAME}" -F preconfig="$PIPELINE" -F data_source="$DATA" || echo "Correlate ${PIPELINE}-${DATA}-${IMAGE_NAME} initiated"

export GITHUB_WORKSPACE="${HOME_DIR}/${IMAGE_NAME}"

cpac_regsuite_create_yaml --pipeline1 "${COMPARISON_PATH}/${PIPELINE}/${DATA}" --pipeline2 "${GITHUB_WORKSPACE}/lite/${PIPELINE}/${DATA}" --workspace "${GITHUB_WORKSPACE}" --data_source "${DATA}"
