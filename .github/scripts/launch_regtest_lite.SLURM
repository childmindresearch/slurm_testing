#!/bin/bash
# Required environment variables: 
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=4

export PUSH_LOGS=true
export _WD=$PWD
mkdir -p "${HOME_DIR}/logs/${SHA}/launch"
cd "${HOME_DIR}/logs/${SHA}" || PUSH_LOGS=false
if [[ $PUSH_LOGS==true ]]
then
  # set up logging repo
  git init
  git remote add origin git@github.com:${OWNER}/regtest-runlogs.git
  git switch -c ${REPO}_${SHA} || git checkout -b ${REPO}_${SHA}
  cd $_WD
fi
PATH=$PATH:$PATH_EXTRA
GH_AVAILABLE=true
cd "${HOME_DIR}/slurm_testing" || exit 1
gh repo set-default "$OWNER/slurm_testing" || GH_AVAILABLE=false

BUILD_SLURM_JOB=$(sbatch --export="image=$IMAGE,PATH=$PATH,SHA=$SHA,working_dir=$HOME_DIR" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" "${HOME_DIR}/slurm_testing/regression_run_scripts/build_image.sh" | awk '{print $4}')

# only launch if build succeeded
LAUNCH_SLURM_JOB=$(sbatch --dependency=afterok:"$BUILD_SLURM_JOB" --export="GH_AVAILABLE=$GH_AVAILABLE,HOME_DIR=$HOME_DIR,IMAGE=$IMAGE,OWNER=$OWNER,PATH=$PATH,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" "${HOME_DIR}/slurm_testing/regression_run_scripts/regtest_lite.sh" | awk '{print $4}')

# Update run check on GitHub Actions
if [ "$GH_AVAILABLE" = true ]
then
  LAUNCH_SUCCESS_JOB=$(sbatch --dependency=afterok:"$LAUNCH_SLURM_JOB" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'launch_success' --export="HOME_DIR=$HOME_DIR,OWNER=$OWNER,PATH=$PATH,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA,STATUS=success" .github/scripts/status_regtest_lite.SLURM | awk '{print $4}')
  LAUNCH_FAILURE_JOB=$(sbatch --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" --dependency=afternotok:"$BUILD_SLURM_JOB"?afternotok:"$LAUNCH_SLURM_JOB" -J 'launch_failure' --export="HOME_DIR=$HOME_DIR,OWNER=$OWNER,PATH=$PATH,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA,STATUS=failure" .github/scripts/status_regtest_lite.SLURM | awk '{print $4}')
  # Delete local logs after pushing them to GitHub
  sbatch --dependency=afterok:"$LAUNCH_FAILURE_JOB" -J 'push_logs' --export="HOME_DIR=$HOME_DIR,IMAGE=$IMAGE,REPO=$REPO,SHA=$SHA,_WD=$_WD" .github/scripts/push_to_github.SLURM
else
  sbatch --dependency=afterok:"$LAUNCH_SLURM_JOB" --output="${HOME_DIR}/logs/${SHA}/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'launch_success' --wrap="echo 'launch succeeded')"
  sbatch --dependency=afternotok:"$BUILD_SLURM_JOB"?afternotok:"$LAUNCH_SLURM_JOB" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'launch_failure' --wrap=">&2 echo 'launch failed')"
fi
