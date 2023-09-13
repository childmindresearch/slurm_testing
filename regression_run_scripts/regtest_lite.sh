#!/usr/bin/bash

exec 2>> "${HOME_DIR}/logs/${SHA}/debug.log"
set -x

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --home_dir) HOME_DIR="$2"; shift ;;
        --image) IMAGE="$2"; shift ;;
        --sha) SHA="$2"; shift ;;
        --owner) OWNER="$2"; shift ;;
        --repo) REPO="$2"; shift ;;
    esac
    shift
done

IMAGE_NAME="${IMAGE#*:}"
# GIT_REPO=${HOME_DIR}/slurm_testing
GIT_REPO="${HOME_DIR}/slurm_testing_callback"
DATA_DIR="${HOME_DIR}/DATA/reg_5mm_pack"
OUT="${HOME_DIR}/${IMAGE_NAME}"
IMAGE="${IMAGE_NAME}.sif"
PIPELINE_CONFIGS="${DATA_DIR}/configs"
PRECONFIGS="default"
DATA_SOURCE="Site-CBIC Site-SI HNU_1"

cd $GIT_REPO || exit 1
gh repo set-default $OWNER/slurm_testing
git fetch origin
git checkout --force origin/regression/after_runs

FULL_SUCCESS_DEPENDENCIES=""

for PIPELINE in ${PRECONFIGS}; do
    for DATA in ${DATA_SOURCE}; do
        if [ ${DATA} == 'HNU_1' ]; then
            subject="sub-0025428"
            DATAPATH=${DATA_DIR}/data/HNU_1
        elif [ ${DATA} == 'Site-CBIC' ]; then
            subject="sub-NDARAB348EWR"
            DATAPATH=${DATA_DIR}/data/Site-CBIC
        elif [ ${DATA} == 'Site-SI' ]; then
            subject="sub-NDARAD481FXF"
            DATAPATH=${DATA_DIR}/data/Site-SI
        fi

        OUTPUT=${OUT}/${PIPELINE}/${DATA}
        [ ! -d  ${OUTPUT} ] && mkdir -p ${OUTPUT}

        cat << TMP > reglite_${IMAGE_NAME}_${PIPELINE}_${DATA}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 10:00:00
#SBATCH --ntasks-per-node=11
#SBATCH -o ${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}/out.log
#SBATCH --error ${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}/error.log
#SBATCH -J ${PIPELINE}-${DATA}-${IMAGE_NAME}-reglite

export SINGULARITY_CACHEDIR=${HOME_DIR}/.singularity/cache \
SINGULARITY_LOCALCACHEDIR=${HOME_DIR}/.singularity/tmp

singularity run \
    --cleanenv \
    -B ${HOME_DIR} \
    -B ${DATAPATH}:/data \
    -B ${OUTPUT}:/outputs \
    -B ${PIPELINE_CONFIGS}:/pipeline_configs \
    ${HOME_DIR}/${PIPELINE}-${DATA}-${IMAGE} /data /outputs participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file /pipeline_configs/${PIPELINE}_lite.yml \
    --participant_label ${subject} \
#     --n_cpus 10 --mem_gb 40
TMP
        # Make the script executable
        chmod +x "reglite_${IMAGE_NAME}_${PIPELINE}_${DATA}.sh"
        # Create a log directory
        mkdir -p "${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}"
        # Create a hardlink for each run
        # so we can delete them as we go
        # and the last one done deletes the image
        cp -fl "${HOME_DIR}/${IMAGE}" "${HOME_DIR}/${PIPELINE}-${DATA}-${IMAGE}"
        REGLITE_JOB=$(sbatch --export="OWNER=$OWNER,PATH=$PATH,REPO=$REPO,SHA=$SHA" --output="${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}/out.log" --error="${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}/error.log" "reglite_${IMAGE_NAME}_${PIPELINE}_${DATA}.sh" | awk '{print $4}')
        gh workflow run "Test run initiated" -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F job="${PIPELINE}-${DATA}-${IMAGE_NAME}" -F preconfig="$PIPELINE" -F data_source="$DATA" || echo "Test run ${PIPELINE}-${DATA}-${IMAGE_NAME} initiated"
        # Update run check on GitHub Actions and correlate if run succeeded
        if [ "$GH_AVAILABLE" = true ]
        then
        REGLITE_SUCCESS_JOB=$(sbatch --dependency=afterok:"$REGLITE_JOB" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'reglite_success' --export="DATA=$DATA,HOME_DIR=$HOME_DIR,OWNER=$OWNER,PATH=$PATH,PIPELINE=$PIPELINE,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA" .github/scripts/correlate_regtest_lite.SLURM | awk '{print $4}')
        REGLITE_FAILURE_JOB=$(sbatch --dependency=afternotok:"$REGLITE_JOB" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'reglite_failure' --export="DATA=$DATA,HOME_DIR=$HOME_DIR,OWNER=$OWNER,PATH=$PATH,PIPELINE=$PIPELINE,PUSH_LOGS=$PUSH_LOGS,REPO=$REPO,SHA=$SHA" .github/scripts/failed_regtest_lite.SLURM | awk '{print $4}')
        else
        # Launch correlation without GH Actions
        >&2 echo "Automatic correlation not yet enabled without GitHub Actions CLI"
        # TODO if anyone wants it (https://en.wikipedia.org/wiki/YAGNI)
        fi
        # Delete run-specific image
        sbatch --dependency=afterany:"$REGLITE_JOB" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'delete_image' --wrap="rm \"${HOME_DIR}/${PIPELINE}-${DATA}-${IMAGE}\""
        if [ -z "$FULL_SUCCESS_DEPENDENCIES" ]
        then
          FULL_SUCCESS_DEPENDENCIES="${REGLITE_JOB}:${REGLITE_SUCCESS_JOB}:${REGLITE_FAILURE_JOB}"
        else
          FULL_SUCCESS_DEPENDENCIES+=":${REGLITE_JOB}:${REGLITE_SUCCESS_JOB}:${REGLITE_FAILURE_JOB}"
        fi
    done
done

# Remove original (non-run-specific) image hardlink & launched runscripts, and push logs to GitHub
sbatch --dependency=afterany:"$FULL_SUCCESS_DEPENDENCIES" --output="${HOME_DIR}/logs/${SHA}/launch/out.log" --error="${HOME_DIR}/logs/${SHA}/launch/error.log" -J 'delete_image_and_push_logs' --export="HOME_DIR=$HOME_DIR,IMAGE=$IMAGE,REPO=$REPO,SHA=$SHA,_WD=$_WD" .github/scripts/push_to_github.SLURM
