#!/usr/bin/bash

# Required environment variables: $COMPARISON_PATH, $GH_AVAILABLE, $HOME_DIR, $IMAGE, $OWNER, $PATH, $PUSH_LOGS, $REPO, $SHA, $TESTING_REPO, $TOKEN_FILE

set -x

# shellcheck disable=SC1090
source "${TOKEN_FILE}"

IMAGE_NAME="${SHA#*:}"
GIT_REPO="${HOME_DIR}/C-PAC_slurm_testing"
DATA_DIR="${HOME_DIR}/DATA/reg_5mm_pack"
OUT="${HOME_DIR}/lite/${IMAGE_NAME}"
# IMAGE="${IMAGE_NAME}.sif"
PRECONFIGS="default"
DATA_SOURCE="Site-CBIC Site-SI HNU_1"

cd "$GIT_REPO" || exit 1
gh repo set-default "$TESTING_REPO"
git fetch origin
git reset --hard origin/main
git checkout --force origin/main
pip install .

for PIPELINE in ${PRECONFIGS}; do

    for DATA in ${DATA_SOURCE}; do

        DATAPATH=${DATA_DIR}/data/${DATA}
        OUTPUT=${OUT}/${PIPELINE}/${DATA}
        [ ! -d "${OUTPUT}" ] && mkdir -p "${OUTPUT}"

        for SUBJECT_PATH in "${DATAPATH}"/sub-*; do
            SUBJECT=$(basename "${SUBJECT_PATH}")
            cpac_slurm_status add --wd="${OUT}" --dry-run --data_source="${DATA_SOURCE}" --preconfig="${PIPELINE}" --subject="${SUBJECT}"

        done
    done
done
