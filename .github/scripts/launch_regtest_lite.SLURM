#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=4
#SBATCH --wrap="bash ${HOME_DIR}/slurm_testing_callback/regression_run_scripts/regtest_lite.sh"

PATH=$PATH:$PATH_EXTRA
cd ${HOME_DIR}/slurm_testing_callback
gh repo set-default $OWNER/slurm_testing

# Update run check on GitHub Actions
if [ $? -eq 0 ]; then
    gh workflow run "Run launch status update" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F status="success" -F log_output="$(cat ${HOME_DIR}/logs/${SHA}/out.log)" -F log_error="$(cat ${HOME_DIR}/logs/${SHA}/error.log)"
else
    gh workflow run "Run launch status update" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F status="failure" -F log_error="$(cat ${HOME_DIR}/logs/${SHA}/error.log)" -F log_output="$(cat ${HOME_DIR}/logs/${SHA}/out.log)"
fi
# Delete local logs after pushing them to GitHub
rm -rf ${HOME_DIR}/logs/${SHA}
