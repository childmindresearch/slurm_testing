#!/usr/bin/bash

exec 2> "${HOME_DIR}/debug.log"
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
#SBATCH -o ${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}.out
#SBATCH --error ${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}.err
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
        chmod +x "reglite_${IMAGE_NAME}_${PIPELINE}_${DATA}.sh"
        # Create a hardlink for each run
        # so we can delete them as we go
        # and the last one done deletes the image
        cp -fl "${HOME_DIR}/${IMAGE}" "${HOME_DIR}/${PIPELINE}-${DATA}-${IMAGE}"
        REGTEST_JOB=$(sbatch --export="OWNER=$OWNER,REPO=$REPO,SHA=$SHA,HOME_DIR=$HOME_DIR,IMAGE=$IMAGE,IMAGE_NAME=$IMAGE_NAME,PIPELINE=$PIPELINE,DATA=$DATA,PATH=$PATH,GH_AVAILABLE=$GH_AVAILABLE" --output="${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}-${IMAGE_NAME}.out" --error="${HOME_DIR}/logs/${SHA}/slurm-${PIPELINE}-${DATA}-${IMAGE_NAME}.err" .github/scripts/run_regtest_lite.SLURM | awk '{print $4}')
        gh workflow run "Test run initiated" -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F job="${PIPELINE}-${DATA}-${IMAGE_NAME}" -F preconfig="$PIPELINE" -F data_source="$DATA" || echo "Test run ${PIPELINE}-${DATA}-${IMAGE_NAME} initiated"
        sbatch --dependency=afternotok:"$REGTEST_JOB" --export="DATA=$DATA,HOME_DIR=$HOME_DIR,IMAGE_NAME=$IMAGE_NAME,OWNER=$OWNER,PATH=$PATH,PIPELINE=$PIPELINE,REPO=$REPO,SHA=$SHA" --output="${PIPELINE}-${DATA}-${IMAGE_NAME}-failed.err" --error="${PIPELINE}-${DATA}-${IMAGE_NAME}-failed.err" .github/scripts/failed_run_regtest_lite.SLURM || echo "Test run failed"
    done
done

# Remove original (non-run-specific) image hardlink & launched runscript
# rm ${IMAGE} reglite_${IMAGE_NAME}_*.sh
