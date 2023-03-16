<b> Regression Testing on Slurm Clusters (ACCESS) </b>
=======================================================

This Github repo allows <a href="https://github.com/FCP-INDI">C-PAC</a> developers to run full regression tests on ACCESS, a cluster under Pittsburgh Computing Center.
The scripts in this repo allow you to submit sbatch jobs on ACCESS. 

<b>Installation Guide:</b>
-------------------------

1. SSH into ACCESS
2. In your project home directory (typically `/ocean/projects/med####p/{username}`), 
   clone this repo 
   ```
   git clone git@github.com:amygutierrez/slurm_testing.git
   ```
3. You're ready to start testing! :technologist:

<br>

<b>What does a C-PAC Regression Test entail?</b>
------------------------------------------
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
  
<b>Script Details:</b>
------------------------

<b>regtest_job_seed.sh</b>

This script will run the singularity image provided against the pipelines and datasets detailed above. 
Every pipeline has fixed the `random_seed` value to `77742777`

```
Arguments:
--username {username}                             Provide your ACCESS username
--out_dir {path/to/desired/output/directory}      Provie the absolute path for the regression test outputs. 
--image_dir {path/to/image.sif}                   Provide the absolute path to the singularity image you want to use
```

EXAMPLE:
To run this script on ACCESS
```
bash /{path_to_repo}/regression_run_scripts/regtest_job_seed.sh --username {username} \
--out_dir /ocean/projects/med####p/{username}/regression_test \
--image_dir /ocean/projects/med####p/{username}/cpac_nightly.sif
```

<br>
<br>

<b>regtest_job_cpac_code.sh</b>

This script will run the singularity image provided _with_ CPAC branch changes against the pipelines and datasets detailed above. 
Every pipeline has fixed the `random_seed` value to `77742777`

```
Arguments:
--username {username}                             Provide your ACCESS username
--out_dir {path/to/desired/output/directory}      Provie the absolute path for the regression test outputs. 
--image_dir {path/to/image.sif}                   Provide the absolute path to the singularity image you want to use
--cpac_dir {path/to/cpac/directory}               Provide the absolute path to CPAC git repository. Make sure C-PAC points
                                                  to desired branch you want to test
```

EXAMPLE:
To run this script on ACCESS
```
bash /{path_to_repo}/regression_run_scripts/regtest_job_seed.sh --username {username} \
--out_dir /ocean/projects/med####p/{username}/regression_test \
--image_dir /ocean/projects/med####p/{username}/cpac_nightly.sif \
--cpac_dir /ocean/projects/med####p/{username}/C-PAC
```

<br>
<br>

<b>TIPS!</b>

  - When running these scripts, run them inside a temporary directory that you can delete later. 
    This is because bash scripts and slurm.out files will get written into the current directory. Example:
    ```
    mkdir -p ./temp_reg_runs
    
    cd ./temp_reg_runs
    
    bash /{path_to_repo}/regression_run_scripts/regtest_job_seed.sh --username {username} \
    --out_dir /ocean/projects/med####p/{username}/regression_test \
    --image_dir /ocean/projects/med####p/{username}/cpac_nightly.sif \
    --cpac_dir /ocean/projects/med####p/{username}/C-PAC
    ```
    
  - If you are testing a specific C-PAC branch, make sure that you pull the branch changes in the C-PAC directory _before_ running `regtest_job_cpac_code.sh`
