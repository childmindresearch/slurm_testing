#!/usr/bin/bash

function create_and_submit_job {
    local PIPELINE=$1
    local DATA=$2
    local OUTPUT=$3
    local TIME=$4
    local DATA_CONFIG_FILE=$5

    cat << TMP > "regtest_${PIPELINE}_${DATA}.sh"
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared,RM-small
#SBATCH -t ${TIME}
#SBATCH --ntasks-per-node=20

export HOME="${HOME}"
apptainer run \
    --cleanenv \
    -B "${MED}" \
    -B "${DATA}":"${DATA}" \
    -B "${CPAC}/CPAC:/code/CPAC" \
    -B "${CPAC}/dev/docker_data/run.py:/code/run.py" \
    -B "${CPAC}/dev/docker_data/run-with-freesurfer.sh:/code/run-with-freesurfer.sh "\
    -B "${OUTPUT}":"${OUTPUT}" \
    -B "${CONFIG}":"${CONFIG}" \
    -B "${PIPELINE_CONFIGS}":"${PIPELINE_CONFIGS}" \
    "${IMAGE}" "${DATA}" "${OUTPUT}" participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file "${PIPELINE_CONFIGS}/${PIPELINE}_seed.yml" \
    --data_config_file "${DATA_CONFIG_FILE}" \
    --n_cpus 18 --mem_gb 40

TMP
    chmod +x "regtest_${PIPELINE}_${DATA}.sh"
    sbatch "regtest_${PIPELINE}_${DATA}.sh"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --username) USER="$2"; shift ;;
        --out_dir) OUT_DIR="$2"; shift ;;
        --image_dir) IMAGE_DIR="$2"; shift ;;
        --cpac_dir) CPAC_DIR="$2"; shift ;;
    esac
    shift
done

MED=/ocean/projects/med220004p
HOME="${MED}/${USER}"
GIT_REPO="${HOME}/C-PAC_slurm_testing"
DATA="${MED}/shared/data_raw/CPAC-Regression"
OUT="${OUT_DIR}"
CONFIG="${GIT_REPO}/data_configs"
IMAGE="${IMAGE_DIR}"
CPAC="${CPAC_DIR}"
PIPELINE_CONFIGS="${GIT_REPO}/pipeline_configs"
PRECONFIGS="default benchmark-FNIRT fmriprep-options ndmg fx-options abcd-options ccs-options rodent monkey"
DATA_SOURCE="KKI Site-CBIC Site-SI HNU_1"

for PIPELINE in ${PRECONFIGS}
do
    if [ "${PIPELINE}" == 'rodent' ] || [ "${PIPELINE}" == 'monkey' ]
    then
        OUTPUT="${OUT}/${PIPELINE}"
        [ ! -d "${OUTPUT}" ] && mkdir -p "${OUTPUT}"

        if [ "${PIPELINE}" == 'rodent' ]
        then
            create_and_submit_job "${PIPELINE}" "${DATA}" "${OUTPUT}" "1:00:00" "${CONFIG}/data_config_regtest_rodent.yml"
        elif [ "${PIPELINE}" == 'monkey' ]
        then
            create_and_submit_job "${PIPELINE}" "${DATA}" "${OUTPUT}" "2:00:00" "${CONFIG}/data_config_regtest_nhp.yml"
        fi

    else

        for SITE in ${DATA_SOURCE}
        do
            OUTPUT="${OUT}/${PIPELINE}/${SITE}"
            [ ! -d  "${OUTPUT}" ] && mkdir -p "${OUTPUT}"

            if [ "${PIPELINE}" == 'abcd-options' ] || [ "${PIPELINE}" == 'ccs-options' ]
            then
                create_and_submit_job "${PIPELINE}" "${DATA}" "${OUTPUT}" "47:00:00" "${CONFIG}/data_config_regtest_${SITE}.yml"
            else
                create_and_submit_job "${PIPELINE}" "${DATA}" "${OUTPUT}" "20:00:00" "${CONFIG}/data_config_regtest_${SITE}.yml"
            fi
        done
    fi
done
