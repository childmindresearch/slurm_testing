#!/bin/bash
# Required environment variables: $OWNER $REPO $SHA $HOME_DIR $STATUS
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 00:05:00
#SBATCH --ntasks-per-node=1

exec 2>> "${HOME_DIR}/logs/${SHA}/debug.log"
set -x

if [[ PUSH_LOGS==true ]]
then
    export _WD=$PWD
    cd "${HOME_DIR}/logs/${SHA}/launch"
    git add error.log out.log
    git commit -m "Add logs for ${PIPELINE} ${DATA} ${SHA}"
    cd $_WD
fi

gh workflow run 'Run launch status update' -F ref="$SHA" -F repo="$REPO" -F owner="$OWNER" -F status="${STATUS}"
