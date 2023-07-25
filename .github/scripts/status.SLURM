#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR

gh repo set-default $OWNER/slurm_testing

# Update run check on GitHub Actions
if [ $SLURM_JOB_STATE = "COMPLETED" ]; then
    gh workflow run "Correlate Regression Test" -F ref=$SHA -F pipeline1="one" -F pipeline2="two" -F repo=$REPO -F owner=$OWNER -F log="$(cat ${home_dir}/logs/${SHA}/out.log)\n$(cat ${home_dir}/logs/${SHA}/error.log)"
elif [ $SLURM_JOB_STATE = "FAILED" ]; then
    gh workflow run "Test run failed" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F log="FAILED:\n$(cat ${home_dir}/logs/${SHA}/error.log)\n$(cat ${home_dir}/logs/${SHA}/out.log)"
else
    gh workflow run "Test run failed" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F log="$SLURM_JOB_STATE:\n$(cat ${home_dir}/logs/${SHA}/error.log)\n$(cat ${home_dir}/logs/${SHA}/out.log)"
fi
# Delete local logs after pushing them to GitHub
rm -rf ${home_dir}/logs/${SHA}