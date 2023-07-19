#!/usr/bin/bash

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --home_dir) home_dir="$2"; shift ;;
        --image) image="$2"; shift ;;
    esac
    shift
done

IMAGE_NAME=${image#*:}
GIT_REPO=${home_dir}/slurm_testing
DATA=${home_dir}/DATA/reg_5mm_pack
OUT=${home_dir}/${IMAGE_NAME}
IMAGE=${IMAGE_NAME}.sif
PIPELINE_CONFIGS=${DATA}/configs
PRECONFIGS="default"
DATA_SOURCE="Site-CBIC Site-SI HNU_1"

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
#SBATCH -t 10:00:00
#SBATCH --ntasks-per-node=11
#SBATCH -o slurm-${pipeline}-${data}.out

SINGULARITY_CACHEDIR=${home_dir}/.singularity/cache \
SINGULARITY_LOCALCACHEDIR=${home_dir}/.singularity/tmp \
singularity build ${IMAGE} docker://${image}

singularity run \
    --cleanenv \
    -B ${home_dir} \
    -B ${datapath}:/data \
    -B ${OUTPUT}:/outputs \
    -B ${PIPELINE_CONFIGS}:/pipeline_configs \
    ${IMAGE} /data /outputs participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file /pipeline_configs/${pipeline}_lite.yml \
    --participant_label ${subject} \
    --n_cpus 10 --mem_gb 40
TMP
        chmod +x reglite_${IMAGE_NAME}_${pipeline}_${data}.sh
        sbatch reglite_${IMAGE_NAME}_${pipeline}_${data}.sh
    done
done

rm reglite_${IMAGE_NAME}_*.sh
rm ${IMAGE}