#!/bin/bash
# Required environment variables: $HOME_DIR $IMAGE $REPO $SHA $_WD
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

exec 2>> "${HOME_DIR}/logs/${SHA}/debug.log"
set -x

export GIT_REPO_DIR="${HOME_DIR}/logs/${SHA}"
cd "${GIT_REPO_DIR}"
source "${HOME_DIR}/slurm_testing_callback/.github/scripts/wait_for_git_lock.sh"
wait_for_git_lock
git push origin ${REPO}_${SHA} -f
cd $_WD
rm -rf "${HOME_DIR}/${IMAGE}"