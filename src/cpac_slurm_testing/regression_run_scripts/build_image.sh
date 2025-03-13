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
mkdir -p "${HOME_DIR}/automatic_tests/images/${SHA}"
IMAGE_PATH="${working_dir}/${IMAGE_NAME}.sif"
cat << TMP > "build_${IMAGE_NAME}.sh"
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 1:00:00
#SBATCH --ntasks=4
#SBATCH -o "${HOME_DIR}/automatic_tests/images/${SHA}/build.out.log"
#SBATCH --error "${HOME_DIR}/automatic_tests/images/${SHA}/build.err.log"

set -x

export APPTAINER_CACHEDIR="${HOME_DIR}/.apptainer/cache" \
       APPTAINER_LOCALCACHEDIR="${HOME_DIR}/.apptainer/tmp"
yes | apptainer cache clean
yes | apptainer build --force "${IMAGE_PATH}" "docker://${image}"

if [ -e "${IMAGE_PATH}" ]
then
  exit 0
else
  exit 2
fi

TMP

chmod +x "build_${IMAGE_NAME}.sh"
sbatch --wait "build_${IMAGE_NAME}.sh"
EXIT_CODE=$?
rm "build_${IMAGE_NAME}.sh"
exit "$EXIT_CODE"
