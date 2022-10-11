#!/usr/bin/bash

MED=/ocean/projects/med220004p
HOME=${MED}/agutierr
DATA=${MED}/shared/data_raw/CPAC-Regression
OUT=${HOME}/reg_test_1.8.4/fixed_seed
CONFIG=${HOME}/configs
IMAGE=${HOME}/c-pac_release-v1.8.4.sif
PIPELINE_CONFIGS=${HOME}/seed_pipelines
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
#SBATCH --ntasks-per-node=7

singularity run \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant --save_working_dir --skip_bids_validator --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml --data_config_file ${CONFIG}/data_config_regtest_rodent.yml --n_cpus 6 --mem_gb 12

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
#SBATCH --ntasks-per-node=7

singularity run \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant --save_working_dir --skip_bids_validator --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml --data_config_file ${CONFIG}/data_config_regtest_nhp.yml --n_cpus 6 --mem_gb 20

TMP
        chmod +x regtest_${pipeline}.sh
        sbatch regtest_${pipeline}.sh
        fi
    
    else

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
#SBATCH -t 46:00:00
#SBATCH --ntasks-per-node=10

singularity run \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant --save_working_dir --skip_bids_validator --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml --data_config_file ${CONFIG}/data_config_regtest_${data}.yml --n_cpus 9 --mem_gb 20

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
#SBATCH --ntasks-per-node=7

singularity run \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant --save_working_dir --skip_bids_validator --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml --data_config_file ${CONFIG}/data_config_regtest_${data}.yml --n_cpus 6 --mem_gb 12

TMP
            chmod +x regtest_${pipeline}_${data}.sh
            sbatch regtest_${pipeline}_${data}.sh

            else
            cat << TMP > regtest_${pipeline}_${data}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 10:00:00
#SBATCH --ntasks-per-node=7

singularity run \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    -B ${PIPELINE_CONFIGS}:${PIPELINE_CONFIGS} \
    ${IMAGE} ${DATA} ${OUTPUT} participant --save_working_dir --skip_bids_validator --pipeline_file ${PIPELINE_CONFIGS}/${pipeline}_seed.yml --data_config_file ${CONFIG}/data_config_regtest_${data}.yml --n_cpus 6 --mem_gb 12

TMP
            chmod +x regtest_${pipeline}_${data}.sh
            sbatch regtest_${pipeline}_${data}.sh
            fi
        done
    fi
done
