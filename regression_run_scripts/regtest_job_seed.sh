#!/usr/bin/bash

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --username) Path="$2"; shift ;;
        --out_dir) Subject="$2"; shift ;;
		--image_dir) LowResMesh="$2"; shift ;;
		--cpac_dir) FinalfMRIResolution="$2"; shift ;;
    esac
    shift
done

MED=/ocean/projects/med220004p
HOME=${MED}/${user}
GIT_REPO=${HOME}/slurm_testing
DATA=${MED}/shared/data_raw/CPAC-Regression
OUT=${out_dir}
CONFIG=${GIT_REPO}/data_configs
IMAGE=${image_dir}
PIPELINE_CONFIGS=${GIT_REPO}/pipeline_configs
PRECONFIGS="default benchmark-FNIRT fmriprep-options ndmg fx-options abcd-options ccs-options rodent monkey"
DATA_SOURCE="KKI Site-CBIC Site-SI HNU_1"

for pipeline in ${PRECONFIGS}
do
    if [ ${pipeline} == 'rodent' ] || [ ${pipeline} == 'monkey' ]
    then        
        OUTPUT=${OUT}/${pipeline}
        [ ! -d  ${OUTPUT} ] && mkdir -p ${OUTPUT}

        if [ ${pipeline} == 'rodent' ]
        then
        cat << TMP > regtest_${pipeline}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 1:00:00
#SBATCH --ntasks-per-node=11

HOME=${HOME} \
singularity run \
    --cleanenv \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml \
    --data_config_file ${CONFIG}/data_config_regtest_rodent.yml \
    --n_cpus 10 --mem_gb 40

TMP
        chmod +x regtest_${pipeline}.sh
        sbatch regtest_${pipeline}.sh

        elif [ ${pipeline} == 'monkey' ]
        then
        cat << TMP > regtest_${pipeline}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 2:00:00
#SBATCH --ntasks-per-node=11

HOME=${HOME} \
singularity run \
    --cleanenv \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml \
    --data_config_file ${CONFIG}/data_config_regtest_nhp.yml \
    --n_cpus 10 --mem_gb 40

TMP
        chmod +x regtest_${pipeline}.sh
        sbatch regtest_${pipeline}.sh
        fi

        for data in ${DATA_SOURCE}
        do
            OUTPUT=${OUT}/${pipeline}/${data}
            [ ! -d  ${OUTPUT} ] && mkdir -p ${OUTPUT}

            if [ ${pipeline} == 'abcd-options' ] || [ ${pipeline} == 'ccs-options' ]
            then
            cat << TMP > regtest_${pipeline}_${data}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 47:50:00
#SBATCH --ntasks-per-node=20

HOME=${HOME} \
singularity run \
    --cleanenv \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml \
    --data_config_file ${CONFIG}/data_config_regtest_${data}.yml \
    --n_cpus 18 --mem_gb 60

TMP
            chmod +x regtest_${pipeline}_${data}.sh
            sbatch regtest_${pipeline}_${data}.sh

            elif [ ${pipeline} == 'fmriprep-options' ] || [ ${pipeline} == 'fx-options' ]
            then
            cat << TMP > regtest_${pipeline}_${data}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 20:00:00
#SBATCH --ntasks-per-node=20

HOME=${HOME} \
singularity run \
    --cleanenv \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml \
    --data_config_file ${CONFIG}/data_config_regtest_${data}.yml \
    --n_cpus 18 --mem_gb 60

TMP
            chmod +x regtest_${pipeline}_${data}.sh
            sbatch regtest_${pipeline}_${data}.sh

            else
            cat << TMP > regtest_${pipeline}_${data}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 14:00:00
#SBATCH --ntasks-per-node=20

HOME=${HOME} \
singularity run \
    --cleanenv \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml \
    --data_config_file ${CONFIG}/data_config_regtest_${data}.yml \
    --n_cpus 18 --mem_gb 60

TMP
            chmod +x regtest_${pipeline}_${data}.sh
            sbatch regtest_${pipeline}_${data}.sh
            fi
        done
    fi
done
