#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=4

PATH=$PATH:$PATH_EXTRA
GH_AVAILABLE=true
cd "${HOME_DIR}/slurm_testing_callback" || exit 1
gh repo set-default "$OWNER/slurm_testing" || GH_AVAILABLE=false

BUILD_SLURM_JOB=$(sbatch --export="PATH=$PATH,working_dir=$HOME_DIR,image=$IMAGE" --output="${HOME_DIR}/logs/${SHA}/out.log" --error="${HOME_DIR}/logs/${SHA}/error.log" "${HOME_DIR}/slurm_testing_callback/regression_run_scripts/build_image.sh" | awk '{print $4}')

# only launch if build succeeded
LAUNCH_SLURM_JOB=$(sbatch --dependency=afterok:"$BUILD_SLURM_JOB" --export="PATH=$PATH,HOME_DIR=$HOME_DIR,IMAGE=$IMAGE,SHA=$SHA,OWNER=$OWNER,REPO=$REPO" --output="${HOME_DIR}/logs/${SHA}/out.log" --error="${HOME_DIR}/logs/${SHA}/error.log" "${HOME_DIR}/slurm_testing_callback/regression_run_scripts/regtest_lite.sh" | awk '{print $4}')

# Update run check on GitHub Actions
if [ "$GH_AVAILABLE" = true ]
then
  LAUNCH_SUCCESS_JOB=$(sbatch --dependency=afterok:"$LAUNCH_SLURM_JOB" --output="${HOMEDIR}/launch-${SHA}.log" --error="${HOMEDIR}/launch-${SHA}.log" -J 'launch_success' --export="PATH=$PATH" --wrap="gh workflow run 'Run launch status update' -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F status='success' -F log_output=\"$(cat \"${HOME_DIR}/logs/${SHA}/out.log\")\" -F log_error=\"$(cat \"${HOME_DIR}/logs/${SHA}/error.log\")\"" | awk '{print $4}')
  LAUNCH_FAILURE_JOB=$(sbatch --output=/dev/null --error=/dev/null --dependency=afternotok:"$BUILD_SLURM_JOB"?afternotok:"$LAUNCH_SLURM_JOB" -J 'launch_failure' --export="PATH=$PATH" --wrap="gh workflow run 'Run launch status update' -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F status='failure' -F log_error=\"$(cat \"${HOME_DIR}/logs/${SHA}/error.log\")\" -F log_output=\"$(cat \"${HOME_DIR}/logs/${SHA}/out.log\")\"" | awk '{print $4}')
  # Delete local logs after pushing them to GitHub
  # sbtach --dependency=afterany:"$LAUNCH_SUCCESS_JOB"?afterany:"$LAUNCH_FAILURE_JOB" -J 'delete_logs' --wrap="rm -rf \"${HOME_DIR}/logs/${SHA}\""
else
  sbatch --dependency=afterok:"$LAUNCH_SLURM_JOB" --output=/dev/null --error=/dev/null -J 'launch_success' --wrap="echo 'launch succeeded' >> \"${HOME_DIR}/logs/${SHA}/out.log\")"
  sbatch --dependency=afternotok:"$BUILD_SLURM_JOB"?afternotok:"$LAUNCH_SLURM_JOB" --output=/dev/null --error=/dev/null -J 'launch_failure' --wrap="echo 'launch failed' >> \"${HOME_DIR}/logs/${SHA}/error.log\")"
fi
