#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $PIPELINE $PUSH_LOGS $DATA
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

exec 2> "${HOME_DIR}/debug.log"
set -x

REGLITE_JOB=$(sbatch --export="OWNER=$OWNER,PATH=$PATH,REPO=$REPO,SHA=$SHA" "reglite_${IMAGE_NAME}_${PIPELINE}_${DATA}.sh" | awk '{print $4}')

# Update run check on GitHub Actions and correlate if run succeeded
if [ "$GH_AVAILABLE" = true ]
then
  REGLITE_SUCCESS_JOB=$(sbatch --dependency=afterok:"$REGLITE_JOB" --output="${HOME_DIR}/logs/${SHA}/launch-${SHA}.log" --error="${HOME_DIR}/logs/${SHA}/launch-${SHA}.log" -J 'reglite_success' --export="DATA=$DATA,HOME_DIR=$HOME_DIR,OWNER=$OWNER,PATH=$PATH,PIPELINE=$PIPELINE,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA" .github/scripts/correlate_regtest_lite.SLURM | awk '{print $4}')
  REGLITE_FAILURE_JOB=$(sbatch --dependency=afternotok:"$REGLITE_JOB" --output="${HOME_DIR}/logs/${SHA}/launch-${SHA}.log" --error="${HOME_DIR}/logs/${SHA}/launch-${SHA}.log" -J 'reglite_failure' --export="DATA=$DATA,HOME_DIR=$HOME_DIR,OWNER=$OWNER,PATH=$PATH,PIPELINE=$PIPELINE,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA" .github/scripts/failed_regtest_lite.SLURM | awk '{print $4}')
  # Delete local logs after pushing them to GitHub
#   sbatch --dependency=afterany:"$REGLITE_SUCCESS_JOB"?afterany:"$REGLITE_FAILURE_JOB" -J 'delete_run_logs' --wrap="rm -rf \"slurm-${PIPELINE}-${DATA}.*\""
else
  # Launch correlation without GH Actions
  >&2 echo "Automatic correlation not yet enabled without GitHub Actions CLI"
  # TODO if anyone wants it (https://en.wikipedia.org/wiki/YAGNI)
fi
# Delete run-specific image
sbatch --dependency=afterany:"$REGLITE_JOB" --output="${HOME_DIR}/logs/${SHA}/launch-${SHA}.log" --error="${HOME_DIR}/logs/${SHA}/launch-${SHA}.log" -J 'delete_image' --wrap="rm \"${HOME_DIR}/${PIPELINE}-${DATA}-${IMAGE}\""
4