#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $PRECONFIG $DATA_SOURCE

gh repo set-default $OWNER/slurm_testing

# Update run check on GitHub Actions and correlate if run succeeded
if [ $SLURM_JOB_STATE = "COMPLETED" ]; then
    gh workflow run "Correlate Regression Test" -F ref=$SHA -F pipeline1="one" -F pipeline2="two" -F repo=$REPO -F owner=$OWNER -F log="$(cat slurm-${PIPELINE}-${DATA}.out)\n$(cat slurm-${PIPELINE}-${DATA}.err)" -F preconfig=$PRECONFIG -F data_source=$DATA_SOURCE
else
    gh workflow run "Test run failed" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F log="$SLURM_JOB_STATE:\n$(cat ${HOME_DIR}/logs/${SHA}/error.log)\n$(cat ${HOME_DIR}/logs/${SHA}/out.log)" -F preconfig=$PRECONFIG -F data_source=$DATA_SOURCE
fi
# Delete local logs after pushing them to GitHub
rm -rf slurm-${PIPELINE}-${DATA}.*