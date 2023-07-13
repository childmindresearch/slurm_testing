#!/usr/bin/bash

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --working_dir) working_dir="$2"; shift ;;
        --image) image="$2"; shift ;;
    esac
    shift
done

image_name=${image#*:}

cat << TMP > job.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 1:00:00
#SBATCH --ntasks-per-node=20
#SBATCH -o build_image.out

SINGULARITY_CACHEDIR=${working_dir}/.singularity/cache \
SINGULARITY_LOCALCACHEDIR=${working_dir}/.singularity/tmp \
singularity build ${image_name}.sif docker://${image}

TMP

chmod +x job.sh
sbatch job.sh
rm job.sh

# After 10 minutes the loop will exit
timeout=600

while [ ! -f build_image.out ];
do
  # When the timeout is equal to zero, show an error and leave the loop.
  if [ "$timeout" == 0 ]; then
    echo "ERROR: Timeout while waiting for slurm job to execute"
    exit 1
  fi

  sleep 1

  # Decrease the timeout of one
  ((timeout--))
done

tail -f build_image.out
