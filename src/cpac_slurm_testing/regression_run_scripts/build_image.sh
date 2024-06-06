#!/usr/bin/bash

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --working_dir) working_dir="$2"; shift ;;
        --image) image="$2"; shift ;;
    esac
    shift
done

IMAGE_NAME="${SHA#*:}"
for _DIR in cache tmp
do
    mkdir -p "${working_dir}/.apptainer/${_DIR}"
done
cat << TMP > "build_${IMAGE_NAME}.sh"
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 1:00:00
#SBATCH --ntasks-per-node=20
#SBATCH -o "${HOME_DIR}/logs/${SHA}/build.out.log"
#SBATCH --error "${HOME_DIR}/logs/${SHA}/build.err.log"

set -x

export APPTAINER_CACHEDIR="${working_dir}/.apptainer/cache" \
       APPTAINER_LOCALCACHEDIR="${working_dir}/.apptainer/tmp"
yes | apptainer cache clean
yes | apptainer build --force "${working_dir}/${IMAGE_NAME}.sif" "docker://${image}"

TMP

chmod +x "build_${IMAGE_NAME}.sh"
sbatch --wait "build_${IMAGE_NAME}.sh"
EXIT_CODE=$?
rm "build_${IMAGE_NAME}.sh"
exit "$EXIT_CODE"
