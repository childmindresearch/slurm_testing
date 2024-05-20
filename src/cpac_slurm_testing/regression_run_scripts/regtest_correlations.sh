#!/usr/bin/bash

#SBATCH -N 1
#SBATCH -p RM-shared,RM-small
#SBATCH -t 24:00:00
#SBATCH --ntasks-per-node=20

preconfig="default"

cd /ocean/projects/med220004p/agutierr/cpac_v1.8.4_VS_v1.8.5_corr_final || return

cat << TMP > regtest_correlations_${preconfig}.sh

#!/usr/bin/bash
echo "Starting Correlations"
python3 /ocean/projects/med220004p/agutierr/CPAC_regtest_pack/cpac_correlations.py \
/ocean/projects/med220004p/agutierr/corr_yml_regtests/v1.8.5/corrtest_${preconfig}_HNU_1.yml

python3 /ocean/projects/med220004p/agutierr/CPAC_regtest_pack/cpac_correlations.py \
/ocean/projects/med220004p/agutierr/corr_yml_regtests/v1.8.5/corrtest_${preconfig}_KKI.yml

python3 /ocean/projects/med220004p/agutierr/CPAC_regtest_pack/cpac_correlations.py \
/ocean/projects/med220004p/agutierr/corr_yml_regtests/v1.8.5/corrtest_${preconfig}_Site-CBIC.yml

python3 /ocean/projects/med220004p/agutierr/CPAC_regtest_pack/cpac_correlations.py \
/ocean/projects/med220004p/agutierr/corr_yml_regtests/v1.8.5/corrtest_${preconfig}_Site-SI.yml

echo "Finished correlation ${preconfig}"
TMP
chmod +x regtest_correlations_${preconfig}.sh

apptainer exec -B /ocean/projects/med220004p/agutierr:/ocean/projects/med220004p/agutierr \
    --cleanenv /ocean/projects/med220004p/agutierr/c-pac_nightly-v1.8.5.sif regtest_correlations_${preconfig}.sh
