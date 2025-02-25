#!/usr/bin/bash

# Required environment variables: $COMPARISON_PATH, $GH_AVAILABLE, $HOME_DIR, $IMAGE, $OWNER, $PATH, $PUSH_LOGS, $REPO, $SHA, $SLURM_TESTING_REPO, $SLURM_TESTING_BRANCH, $TOKEN_FILE

set -x

export _CPAC_STATUS_HOME_DIR="${HOME_DIR}"
export _CPAC_STATUS_IMAGE_NAME="${SHA#*:}"
export _CPAC_STATUS_OUT="${HOME_DIR}/full/${_CPAC_STATUS_IMAGE_NAME}"
export _CPAC_STATUS_PRECONFIGS="default"
export _CPAC_STATUS_SHA="${SHA}"
export _CPAC_STATUS_DATA_SOURCE="Site-CBIC Site-SI HNU_1"
export _CPAC_STATUS_WD="${WD}"
# shellcheck disable=SC1090
source "${TOKEN_FILE}" && ./regtest_full.py
