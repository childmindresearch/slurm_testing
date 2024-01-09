#!/usr/bin/bash

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
  mkdir -p "${working_dir}/.singularity/${_DIR}"
done
cat << TMP > "build_${image_name}.sh"
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 1:00:00
#SBATCH --ntasks-per-node=20
#SBATCH -o ${working_dir}/logs/${SHA}/launch/out.log
#SBATCH --error ${working_dir}/logs/${SHA}/launch/error.log

export SINGULARITY_CACHEDIR=${working_dir}/.singularity/cache \
       SINGULARITY_LOCALCACHEDIR=${working_dir}/.singularity/tmp
yes | singularity cache clean
yes | singularity build ${working_dir}/${image_name}.sif docker://${image}

TMP

chmod +x "build_${image_name}.sh"
sbatch --wait "build_${image_name}.sh"
EXIT_CODE=$?
rm "build_${image_name}.sh"
exit $EXIT_CODE
