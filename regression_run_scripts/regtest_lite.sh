#!/usr/bin/bash

# Required environment variables: $COMPARISON_PATH, $GH_AVAILABLE, $HOME_DIR, $IMAGE, $OWNER, $PATH, $PUSH_LOGS, $REPO, $SHA, $TESTING_REPO

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --home_dir) HOME_DIR="$2"; shift ;;
        --image) IMAGE="$2"; shift ;;
        --sha) SHA="$2"; shift ;;
        --owner) OWNER="$2"; shift ;;
        --testing_repo) TESTING_REPO="$2"; shift ;;
        --repo) REPO="$2"; shift ;;
    esac
    shift
done

IMAGE_NAME="${IMAGE#*:}"
GIT_REPO="${HOME_DIR}/slurm_testing"
DATA_DIR="${HOME_DIR}/DATA/reg_5mm_pack"
OUT="${HOME_DIR}/lite/${IMAGE_NAME}"
IMAGE="${IMAGE_NAME}.sif"
PIPELINE_CONFIGS="${GIT_REPO}/pipeline_configs"
PRECONFIGS="default"
DATA_SOURCE="Site-CBIC Site-SI HNU_1"

cd "$GIT_REPO" || exit 1
gh repo set-default "$TESTING_REPO"
git fetch origin
git reset --hard origin/main
git checkout --force origin/main

FULL_SUCCESS_DEPENDENCIES=""
pip install git+https://github.com/shnizzedy/dashboard@correlate_D3

for PIPELINE in ${PRECONFIGS}; do

    for DATA in ${DATA_SOURCE}; do

        DATAPATH=${DATA_DIR}/data/${DATA}
        OUTPUT=${OUT}/${PIPELINE}/${DATA}
        REGLITE_JOBS=""
        [ ! -d "${OUTPUT}" ] && mkdir -p "${OUTPUT}"

        for SUBJECT_PATH in "${DATAPATH}"/sub-*; do
            SUBJECT=$(basename "${SUBJECT_PATH}")
            PDSD="${PIPELINE}-${DATA}-${SUBJECT}"
            PDSU="${PIPELINE}_${DATA}_${SUBJECT}"
            cat << TMP > "reglite_${IMAGE_NAME}_${PDSU}.sh"
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 10:00:00
#SBATCH --ntasks-per-node=11
#SBATCH -o ${HOME_DIR}/logs/${SHA}/slurm-${PDSD}/out.log
#SBATCH --error ${HOME_DIR}/logs/${SHA}/slurm-${PDSD}/error.log
#SBATCH -J ${PDSD}-${IMAGE_NAME}-reglite

export SINGULARITY_CACHEDIR=${HOME_DIR}/.singularity/cache \
SINGULARITY_LOCALCACHEDIR=${HOME_DIR}/.singularity/tmp

singularity run \
    --cleanenv \
    -B ${HOME_DIR} \
    -B ${DATAPATH}:/data \
    -B ${DATA_DIR}:/reg-data \
    -B ${OUTPUT}:/outputs \
    -B ${PIPELINE_CONFIGS}:/pipeline_configs \
    ${HOME_DIR}/${PDSD}-${IMAGE} /data /outputs participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file /pipeline_configs/${PIPELINE}-5mm.yml \
    --participant_label ${SUBJECT} \
    --n_cpus 10 --mem_gb 40

if grep -q "CPAC run complete" ${HOME_DIR}/logs/${SHA}/slurm-${PDSD}/out.log
then
  exit 0  # Exit with success code
else
  exit 1  # Exit with failure code
fi
TMP
            # Make the script executable
            chmod +x "reglite_${IMAGE_NAME}_${PDSU}.sh"
            # Create a log directory
            mkdir -p "${HOME_DIR}/logs/${SHA}/slurm-${PDSD}"
            # Create a hardlink for each run
            # so we can delete them as we go
            # and the last one done deletes the image
            cp -fl "${HOME_DIR}/${IMAGE}" "${HOME_DIR}/${PDSD}-${IMAGE}"
            REGLITE_JOB=$(sbatch --export="OWNER=$OWNER,PATH=$PATH,REPO=$REPO,SHA=$SHA" --output="${HOME_DIR}/logs/${SHA}/slurm-${PDSD}/out.log" --error="${HOME_DIR}/logs/${SHA}/slurm-${PDSD}/error.log" "reglite_${IMAGE_NAME}_${PDSU}.sh" | awk '{print $4}')
            gh workflow run "Initiate check" -F task="run" -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F job="${PDSD}-${IMAGE_NAME}" -F preconfig="$PIPELINE" -F data_source="$DATA" || echo "Test run ${PDSD}-${IMAGE_NAME} initiated"
            if [ -z "$REGLITE_JOBS" ]
            then
              REGLITE_JOBS="${REGLITE_JOB}"
            else
              REGLITE_JOBS+=":${REGLITE_JOB}"
            fi
        done
        # Update run check on GitHub Actions and correlate if run succeeded
        if [ "$GH_AVAILABLE" = true ]
        then
        REGLITE_SUCCESS_JOB=$(sbatch --dependency=afterok:"$REGLITE_JOBS" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'reglite_success' --export="COMPARISON_PATH=$COMPARISON_PATH,DATA=$DATA,HOME_DIR=$HOME_DIR,OWNER=$OWNER,PATH=$PATH,PIPELINE=$PIPELINE,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA" .github/scripts/correlate_regtest_lite.SLURM | awk '{print $4}')
        REGLITE_FAILURE_JOB=$(sbatch --dependency=afternotok:"$REGLITE_JOBS" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'reglite_failure' --export="DATA=$DATA,HOME_DIR=$HOME_DIR,OWNER=$OWNER,PATH=$PATH,PIPELINE=$PIPELINE,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA" .github/scripts/failed_regtest_lite.SLURM | awk '{print $4}')
        else
        # Launch correlation without GH Actions
        >&2 echo "Automatic correlation not yet enabled without GitHub Actions CLI"
        # TODO if anyone wants it (https://en.wikipedia.org/wiki/YAGNI)
        fi
        # Delete run-specific image
        sbatch --dependency=afterany:"$REGLITE_JOBS" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'delete_image' --wrap="rm \"${HOME_DIR}/${PDSD}-${IMAGE}\""
        if [ -z "$FULL_SUCCESS_DEPENDENCIES" ]
        then
          FULL_SUCCESS_DEPENDENCIES="${REGLITE_JOBS}:${REGLITE_SUCCESS_JOB}:${REGLITE_FAILURE_JOB}"
        else
          FULL_SUCCESS_DEPENDENCIES+=":${REGLITE_JOBS}:${REGLITE_SUCCESS_JOB}:${REGLITE_FAILURE_JOB}"
        fi
    done
done

# Remove original (non-run-specific) image hardlink & launched runscripts, and push logs to GitHub
sbatch --dependency=afterany:"$FULL_SUCCESS_DEPENDENCIES" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'delete_image_and_push_logs' --export="HOME_DIR=$HOME_DIR,IMAGE=$IMAGE,REPO=$REPO,SHA=$SHA,_WD=$_WD" .github/scripts/push_to_github.SLURM
