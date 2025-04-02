#!/usr/bin/bash

# Required environment variables: $HOME_DIR, $SHA, $TESTING_PATHS, $TOKEN_FILE

set -x

export _CPAC_STATUS_HOME_DIR="${HOME_DIR}"
export _CPAC_STATUS_IMAGE_NAME="${SHA#*:}"
export _CPAC_STATUS_OUT="${HOME_DIR}/automatic_tests/full/${_CPAC_STATUS_IMAGE_NAME}"
export _CPAC_STATUS_PRECONFIGS="default"
export _CPAC_STATUS_SHA="${SHA}"
export _CPAC_STATUS_DATA_SOURCE="Site-CBIC Site-SI HNU_1"
export _CPAC_STATUS_WD="${TESTING_PATHS}"
export _CPAC_STATUS_TOKEN_FILE="${TOKEN_FILE}"
"${CPAC_REGTEST_SCRIPT}"
