#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $PIPELINE $DATA
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=4

gh repo set-default "$OWNER/slurm_testing" || GH_AVAILABLE=false
REGLITE_JOB=$(sbatch --export="PATH=$PATH" "reglite_${IMAGE_NAME}_${PIPELINE}_${DATA}.sh" | awk '{print $4}')

# Update run check on GitHub Actions and correlate if run succeeded
if [ "$GH_AVAILABLE" = true ]
then
  REGLITE_SUCCESS_JOB=$(sbatch --dependency=afterok:"$REGLITE_JOB" -J 'reglite_success' --export="PATH=$PATH" --wrap="gh workflow run 'Correlate Regression Test' -F ref=\"$SHA\" -F pipeline1='one' -F pipeline2='two' -F repo=\"$REPO\" -F owner=\"$OWNER\" -F log_output=\"$(cat \"slurm-${PIPELINE}-${DATA}.out\")\" -F log_error=\"$(cat \"slurm-${PIPELINE}-${DATA}.err\")\" -F preconfig=\"$PIPELINE\" -F data_source=\"$DATA\"" | awk '{print $4}')
  REGLITE_FAILURE_JOB=$(sbatch --dependency=afternotok:"$REGLITE_JOB" -J 'reglite_failure' --export="PATH=$PATH" --wrap="gh workflow run 'Test run failed' -F ref=\"$SHA\" -F repo=\"$REPO\" -F owner=\"$OWNER\" -F log_output=\"$(cat \"slurm-${PIPELINE}-${DATA}.out\")\" -F log_error=\"$(cat \"slurm-${PIPELINE}-${DATA}.err\")\" -F preconfig=\"$PIPELINE\" -F data_source=\"$DATA\"" | awk '{print $4}')
  # Delete local logs after pushing them to GitHub
  sbatch --dependency=afterany:"$REGLITE_SUCCESS_JOB"?afterany:"$REGLITE_FAILURE_JOB" -J 'delete_run_logs' --wrap="rm -rf \"slurm-${PIPELINE}-${DATA}.*\""
else
  # Launch correlation without GH Actions
  echo "Automatic correlation not yet enabled without GitHub Actions CLI"
  # TODO if anyone wants it (https://en.wikipedia.org/wiki/YAGNI)
fi
# Delete run-specific image
sbatch --dependency=afterany:"$REGLITE_JOB" -J 'delete_image' --wrap="rm \"${HOME_DIR}/${PIPELINE}-${DATA}-${IMAGE}\""
