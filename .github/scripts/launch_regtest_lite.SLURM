#!/bin/bash
# Required environment variables:
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=4

set -x

export PUSH_LOGS=true
export _WD=$PWD
mkdir -p "${HOME_DIR}/logs/${SHA}/launch"
cd "${HOME_DIR}/logs/${SHA}" || PUSH_LOGS=false
if [[ $PUSH_LOGS == true ]]
then
    # set up logging repo
    git init
    git remote add origin "git@github.com:${OWNER}/regtest-runlogs.git"
    git switch -c "${REPO}_${SHA}" || git checkout -b "${REPO}_${SHA}"
    cd "$_WD" || exit 1
fi
PATH=$PATH:$PATH_EXTRA
GH_AVAILABLE=true
cd "${HOME_DIR}/C-PAC_slurm_testing" || exit 1
gh repo set-default "${TESTING_REPO}" || GH_AVAILABLE=false

BUILD_SLURM_JOB=$(sbatch --parsable --export="image=$IMAGE,PATH=$PATH,SHA=$SHA,working_dir=$HOME_DIR" --output="${HOME_DIR}/logs/${SHA}/launch/%x.out.log" --error="${HOME_DIR}/logs/${SHA}/launch/%x.error.log" "${HOME_DIR}/C-PAC_slurm_testing/regression_run_scripts/build_image.sh")

# only launch if build succeeded
sbatch --dependency=afterok:"$BUILD_SLURM_JOB" --export="COMPARISON_PATH=$COMPARISON_PATH,GH_AVAILABLE=$GH_AVAILABLE,HOME_DIR=$HOME_DIR,IMAGE=$IMAGE,OWNER=$OWNER,PATH=$PATH,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA" --output="${HOME_DIR}/logs/${SHA}/launch/%x.out.log" --error="${HOME_DIR}/logs/${SHA}/launch/%x.error.log" "${HOME_DIR}/C-PAC_slurm_testing/regression_run_scripts/regtest_lite.sh"
