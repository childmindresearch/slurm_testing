#!/usr/bin/bash

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --working_dir) working_dir="$2"; shift ;;
        --image) image="$2"; shift ;;
    esac
    shift
done

cat << TMP > job.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 1:00:00
#SBATCH --ntasks-per-node=20

SINGULARITY_CACHEDIR=${working_dir}/.singularity/cache \
SINGULARITY_LOCALCACHEDIR=${working_dir}/.singularity/tmp \
singularity build ${image}.sif docker://${image}

TMP

chmod +x job.sh
sbatch job.sh
rm job.sh