#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR
# Optional environment variables: $PRECONFIG $DATA_SOURCE

gh repo set-default $OWNER/slurm_testing

# Update run check on GitHub Actions
if [ $SLURM_JOB_STATE = "COMPLETED" ]; then
    gh workflow run "Run launch status update" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F status="success" -F log_output="$(cat ${home_dir}/logs/${SHA}/out.log)" -F log_error="$(cat ${home_dir}/logs/${SHA}/error.log)"
else
    gh workflow run "Run launch status update" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F status="failure" -F log_error="$(cat ${home_dir}/logs/${SHA}/error.log)" -F log_output="$(cat ${home_dir}/logs/${SHA}/out.log)"
fi
# Delete local logs after pushing them to GitHub
rm -rf ${home_dir}/logs/${SHA}
