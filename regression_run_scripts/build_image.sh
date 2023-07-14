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

while : ; do
    [[ -f build_image.out ]] && break
    echo "Pausing until file exists."
    sleep 1
done

if [ -f build_image.out ]; then
    tail -f build_image.out
    exit 0
fi
