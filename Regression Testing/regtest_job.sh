#!/usr/bin/bash

MED=/ocean/projects/med220004p
HOME=/ocean/projects/med220004p/agutierr
DATA=${MED}/shared/data_raw/CPAC-Regression
OUT=${HOME}/reg_test_1.8.4
CONFIG=${HOME}/configs
IMAGE=${HOME}/c-pac_release-v1.8.4.sif
PRECONFIGS="default benchmark-FNIRT ndmg fmriprep-options fx-options abcd-options ccs-options"
DATA_SOURCE="KKI Site-CBIC Site-SI HNU_1"

for pipeline in ${PRECONFIGS}
do

    for data in ${DATA_SOURCE}
    do
        OUTPUT=${OUT}/${pipeline}/${data}
        [ ! -d  ${OUTPUT} ] && mkdir -p ${OUTPUT}

        if [ ${pipeline} == 'default' ]
        then

        cat << TMP > regtest_${pipeline}_${data}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 02:00:00
#SBATCH --ntasks-per-node=7

singularity run \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    ${IMAGE} ${DATA} ${OUTPUT} participant --save_working_dir --skip_bids_validator --data_config_file ${CONFIG}/data_config_regtest_${data}.yml --n_cpus 6 --mem_gb 12

TMP
        chmod +x regtest_${pipeline}_${data}.sh
        sbatch regtest_${pipeline}_${data}.sh

        else

        cat << TMP > regtest_${pipeline}_${data}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 02:00:00
#SBATCH --ntasks-per-node=7

singularity run \
    -B ${MED} \
    -B ${DATA}:${DATA} \
    -B ${OUTPUT}:${OUTPUT} \
    -B ${CONFIG}:${CONFIG} \
    ${IMAGE} ${DATA} ${OUTPUT} participant --save_working_dir --skip_bids_validator --preconfig ${pipeline} --data_config_file ${CONFIG}/data_config_regtest_${data}.yml --n_cpus 6 --mem_gb 12

TMP
        chmod +x regtest_${pipeline}_${data}.sh
        sbatch regtest_${pipeline}_${data}.sh
        fi
    done
done
