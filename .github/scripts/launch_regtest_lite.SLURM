#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=4

PATH=$PATH:$PATH_EXTRA
cd ${HOME_DIR}/slurm_testing_callback
gh repo set-default $OWNER/slurm_testing

BUILD_SLURM_JOB=$(sbatch --export="PATH=$PATH,working_dir=$HOME_DIR,image=$IMAGE" --output="${HOME_DIR}/logs/${SHA}/out.log" --error="${HOME_DIR}/logs/${SHA}/error.log" ${HOME_DIR}/slurm_testing_callback/regression_run_scripts/build_image.sh | awk '{print $4}')

# only launch if build succeeded
LAUNCH_SLURM_JOB=$(sbatch --dependency=afterok:$BUILD_SLURM_JOB --export="PATH=$PATH,HOME_DIR=$HOME_DIR,IMAGE=$IMAGE,SHA=$SHA,OWNER=$OWNER,REPO=$REPO" --output="${HOME_DIR}/logs/${SHA}/out.log" --error="${HOME_DIR}/logs/${SHA}/error.log" ${HOME_DIR}/slurm_testing_callback/regression_run_scripts/regtest_lite.sh | awk '{print $4}')

# Update run check on GitHub Actions
sbatch --dependency=afterok:$LAUNCH_SLURM_JOB --wrap='gh workflow run "Run launch status update" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F status="success" -F log_output="$(cat ${HOME_DIR}/logs/${SHA}/out.log)" -F log_error="$(cat ${HOME_DIR}/logs/${SHA}/error.log)"'
sbatch --dependency=afternotok:$BUILD_SLURM_JOB?afternotok:$LAUNCH_SLURM_JOB 'gh workflow run "Run launch status update" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F status="failure" -F log_error="$(cat ${HOME_DIR}/logs/${SHA}/error.log)" -F log_output="$(cat ${HOME_DIR}/logs/${SHA}/out.log)"'

# Delete local logs after pushing them to GitHub
rm -rf ${HOME_DIR}/logs/${SHA}
