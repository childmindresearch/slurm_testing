#!/usr/bin/bash

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --home_dir) HOME_DIR="$2"; shift ;;
        --image) image="$2"; shift ;;
        --path-extra) export PATH="$PATH:$2"; shift ;;
        --sha) SHA="$2"; shift ;;
        --owner) OWNER="$2"; shift ;;
        --repo) REPO="$2"; shift ;;
    esac
    shift
done

IMAGE_NAME=${image#*:}
GIT_REPO=${HOME_DIR}/slurm_testing
GIT_REPO_TEST=${HOME_DIR}/slurm_testing_callback
DATA=${HOME_DIR}/DATA/reg_5mm_pack
OUT=${HOME_DIR}/${IMAGE_NAME}
IMAGE=${IMAGE_NAME}.sif
PIPELINE_CONFIGS=${DATA}/configs
PRECONFIGS="default"
DATA_SOURCE="Site-CBIC Site-SI HNU_1"

cd $GIT_REPO_TEST

for pipeline in ${PRECONFIGS}; do
    for data in ${DATA_SOURCE}; do
        if [ ${data} == 'HNU_1' ]; then
            subject="sub-0025428"
            datapath=${DATA}/data/HNU_1
        elif [ ${data} == 'Site-CBIC' ]; then
            subject="sub-NDARAB348EWR"
            datapath=${DATA}/data/Site-CBIC
        elif [ ${data} == 'Site-SI' ]; then
            subject="sub-NDARAD481FXF"
            datapath=${DATA}/data/Site-SI
        fi

        OUTPUT=${OUT}/${pipeline}/${data}
        [ ! -d  ${OUTPUT} ] && mkdir -p ${OUTPUT}

        cat << TMP > reglite_${IMAGE_NAME}_${pipeline}_${data}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
# #SBATCH -t 10:00:00
# #SBATCH --ntasks-per-node=11
#SBATCH -o slurm-${pipeline}-${data}.out
#SBATCH --wrap "OWNER=$OWNER REPO=$REPO SHA=$SHA HOME_DIR=$HOME_DIR ./$GIT_REPO/.github/scripts/status.SLRUM"

# SINGULARITY_CACHEDIR=${HOME_DIR}/.singularity/cache \
# SINGULARITY_LOCALCACHEDIR=${HOME_DIR}/.singularity/tmp \
# singularity build ${IMAGE} docker://${image}

# singularity run \
#     --cleanenv \
#     -B ${HOME_DIR} \
#     -B ${datapath}:/data \
#     -B ${OUTPUT}:/outputs \
#     -B ${PIPELINE_CONFIGS}:/pipeline_configs \
#     ${IMAGE} /data /outputs participant \
#     --save_working_dir --skip_bids_validator \
#     --pipeline_file /pipeline_configs/${pipeline}_lite.yml \
#     --participant_label ${subject} \
#     --n_cpus 10 --mem_gb 40
# TMP
#         chmod +x reglite_${IMAGE_NAME}_${pipeline}_${data}.sh
#         sbatch reglite_${IMAGE_NAME}_${pipeline}_${data}.sh
#     done
# done

rm reglite_${IMAGE_NAME}_*.sh
# rm ${IMAGE}
