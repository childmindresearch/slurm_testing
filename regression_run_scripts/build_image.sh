#!/usr/bin/bash

exec 2> "${HOME_DIR}/debug.log"
set -x

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --working_dir) working_dir="$2"; shift ;;
        --image) image="$2"; shift ;;
    esac
    shift
done

image_name=${image#*:}
for _DIR in cache tmp
do
  mkdir -p ${working_dir}/.singularity/${_DIR}
done
cat << TMP > job.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 1:00:00
#SBATCH --ntasks-per-node=20
#SBATCH -o ${working_dir}/logs/${SHA}/launch/out.log
#SBATCH --error ${working_dir}/logs/${SHA}/launch/error.log

SINGULARITY_CACHEDIR=${working_dir}/.singularity/cache \
SINGULARITY_LOCALCACHEDIR=${working_dir}/.singularity/tmp \
yes | singularity build ${working_dir}/${image_name}.sif docker://${image}

TMP

chmod +x job.sh
sbatch --wait job.sh
EXIT_CODE=$?
rm job.sh
exit $EXIT_CODE
