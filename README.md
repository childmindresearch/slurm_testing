# Regression Testing on SLURM Clusters (Bridges-2)

This Github repo allows [C-PAC developers](https://github.com/orgs/FCP-INDI/teams/developers) to run full regression tests on [Bridges-2, a cluster under Pittsburgh Computing Center](https://www.psc.edu/resources/bridges-2/user-guide/).
The scripts in this repo allow you to submit `sbatch` jobs on Bridges-2.

Note: this repository is currently in the process of transitioning to a <span title="continuous integration">CI</span>-initiated flow from a manually initiated flow and contains code and documentation for both during the transition period.

## GitHub Actions initiated

pass

## Manually initiated

### Installation Guide

1. `SSH` into Bridges-2
2. In your project home directory (typically `/ocean/projects/med####p/{username}`),
   clone this repo

   ```shell
   git clone git@github.com:amygutierrez/slurm_testing.git
   ```

3. You're ready to start testing! :technologist:

### What does a C-PAC Regression Test entail?

Regression testing for C-PAC means that certain pipelines and certain datasets will be used for testing.
Full regression testing requires ALOT of computaional resources, so will need to run this on a cluster.

Regression testing pipelines tested:

- default
- benchmark-FNIRT
- fmriprep-options
- ndmg
- fx-options
- abcd-options
- ccs-options
- rodent
- monkey
  
Regression testing datasets used:

- KKI (5 subjects)
- HNU_1 (5 subjects)
- Site-CBIC (4 subjects)
- Site-SI (3 subjects)
  
### Script Details

#### [`regtest_job_seed.sh`](./regression_run_scripts/regtest_job_seed.sh)

This script will run the singularity image provided against the pipelines and datasets detailed above.
Every pipeline has fixed the `random_seed` value to `77742777`

```txt
Arguments:
--username {username}                             Provide your Bridges-2 username
--out_dir {path/to/desired/output/directory}      Provie the absolute path for the regression test outputs. 
--image_dir {path/to/image.sif}                   Provide the absolute path to the singularity image you want to use
```

##### EXAMPLE

To run this script on Bridges-2

```BASH
bash "/${PATH_TO_REPO}/regression_run_scripts/regtest_job_seed.sh" --username "${USERNAME}" \
--out_dir "/ocean/projects/med####p/${USERNAME}/regression_test" \
--image_dir "/ocean/projects/med####p/${USERNAME}/cpac_nightly.sif"
```

#### [`regtest_job_cpac_code.sh`](./regression_run_scripts/regtest_job_cpac_code.sh)

This script will run the singularity image provided _with_ CPAC branch changes against the pipelines and datasets detailed above.
Every pipeline has fixed the `random_seed` value to `77742777`

```txt
Arguments:
--username {username}                             Provide your Bridges-2 username
--out_dir {path/to/desired/output/directory}      Provie the absolute path for the regression test outputs. 
--image_dir {path/to/image.sif}                   Provide the absolute path to the singularity image you want to use
--cpac_dir {path/to/cpac/directory}               Provide the absolute path to CPAC git repository. Make sure C-PAC points
to desired branch you want to test
```

##### EXAMPLE

To run this script on Bridges-2

```BASH
bash "/${PATH_TO_REPO}/regression_run_scripts/regtest_job_seed.sh" --username "${USERNAME}" \
--out_dir "/ocean/projects/med####p/${USERNAME}/regression_test" \
--image_dir "/ocean/projects/med####p/${USERNAME}/cpac_nightly.sif" \
--cpac_dir "/ocean/projects/med####p/${USERNAME}/C-PAC"
```

### TIPS!

- When running these scripts, run them inside a temporary directory that you can delete later.
This is because bash scripts and slurm.out files will get written into the current directory. Example:

```BASH
mkdir -p ./temp_reg_runs

cd ./temp_reg_runs

bash "/${PATH_TO_REPO}/regression_run_scripts/regtest_job_seed.sh" --username "${USERNAME}" \
--out_dir "/ocean/projects/med####p/${USERNAME}/regression_test" \
--image_dir "/ocean/projects/med####p/${USERNAME}/cpac_nightly.sif" \
--cpac_dir "/ocean/projects/med####p/${USERNAME}/C-PAC"
```
  
- If you are testing a specific C-PAC branch, make sure that you pull the branch changes in the C-PAC directory _before_ running `regtest_job_cpac_code.sh`
