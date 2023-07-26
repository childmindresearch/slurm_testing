#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $PIPELINE $DATA
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=4
#SBATCH --wrap "reglite_${IMAGE_NAME}_${PIPELINE}_${DATA}.sh"

gh repo set-default $OWNER/slurm_testing

# Update run check on GitHub Actions and correlate if run succeeded
if [ $? -eq 0 ]; then
    gh workflow run "Correlate Regression Test" -F ref=$SHA -F pipeline1="one" -F pipeline2="two" -F repo=$REPO -F owner=$OWNER -F log_output="$(cat slurm-${PIPELINE}-${DATA}.out)" -F log_error="$(cat slurm-${PIPELINE}-${DATA}.err)" -F preconfig=$PIPELINE -F data_source=$DATA
else
    gh workflow run "Test run failed" -F ref=$SHA -F repo=$REPO -F owner=$OWNER -F log_output="$(cat slurm-${PIPELINE}-${DATA}.out)" -F log_error="$(cat slurm-${PIPELINE}-${DATA}.err)" -F preconfig=$PIPELINE -F data_source=$DATA
fi
# Delete local logs after pushing them to GitHub
rm -rf slurm-${PIPELINE}-${DATA}.*