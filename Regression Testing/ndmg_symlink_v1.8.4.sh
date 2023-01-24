#!/usr/bin/bash

subject="$1"
session1="$2"
session2="$3"
func_run1="$4"
func_run2="$5"

echo "Subject: ${1}"
echo "Session ID old: ${2}"
echo "Session ID new: ${3}"
echo "Func task rest run old: ${4}"
echo "Func task rest run new: ${5}"

echo "Starting symlink for anat directory...."

subject_list="$(ls)"
if [[ ${subject_list} != *"sub-"* ]];then
    prefix="sub-"
    sub_no_prefix=${subject#"$prefix"}
    echo "subject no prefix $sub_no_prefix"
    cd "$sub_no_prefix"/ses-1
else
    cd ${subject}/ses-1
fi

### ANAT ####
cd anat

# from t1w to template
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_xfm.nii.gz

# from template to t1w
ln -s ${subject}_${session1}_from-template_to-T1w_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6ASym_to-T1w_mode-image_desc-linear_xfm.nii.gz

# native regressors 
ln -s ${subject}_${session1}_label-CSF_desc-preproc_mask.nii.gz ${subject}_${session2}_label-CSF_desc-preproc_mask.nii.gz

# brain mask
ln -s ${subject}_${session1}_space-T1w_desc-brain_mask.nii.gz ${subject}_${session2}_space-MNI152NLin6ASym_desc-brain_mask.nii.gz
ln -s ${subject}_${session1}_label-CSF_mask.nii.gz ${subject}_${session2}_label-CSF_mask.nii.gz
ln -s ${subject}_${session1}_label-CSF_probseg.nii.gz ${subject}_${session2}_label-CSF_probseg.nii.gz

ln -s ${subject}_${session1}_label-GM_desc-preproc_mask.nii.gz ${subject}_${session2}_label-GM_desc-preproc_mask.nii.gz
ln -s ${subject}_${session1}_label-GM_mask.nii.gz ${subject}_${session2}_label-GM_mask.nii.gz
ln -s ${subject}_${session1}_label-GM_probseg.nii.gz ${subject}_${session2}_label-GM_probseg.nii.gz

ln -s ${subject}_${session1}_label-WM_desc-preproc_mask.nii.gz ${subject}_${session2}_label-WM_desc-preproc_mask.nii.gz
ln -s ${subject}_${session1}_label-WM_mask.nii.gz ${subject}_${session2}_label-WM_mask.nii.gz
ln -s ${subject}_${session1}_label-WM_probseg.nii.gz ${subject}_${session2}_label-WM_probseg.nii.gz

echo "anat symlink finished...."
echo "........................."
echo "Starting symlink for func directory...."

### FUNC ####
cd ..
cd func

## templates

# AALspace
ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6ASym_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6ASymMNI152NLin6ASym_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6ASym_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6ASym_desc-PearsonNilearn_correlations.tsv

# Brodmannspace
ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6ASym_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6ASymMNI152NLin6ASym_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6ASym_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6ASym_desc-PearsonNilearn_correlations.tsv

# CPAC200
ln -s ${subject}_${session1}_${func_run1}_atlas-CPAC200space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-CPAC200_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-CPAC200space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-CPAC200_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-CPAC200space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CPAC200_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-CPAC200space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations ${subject}_${session2}_${func_run2}_atlas-CPAC200_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# Deskian
ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DKTspace
ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00071
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00071space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00071_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00071space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00071_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00071space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00071_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00071space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00071_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00096
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00096space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00096_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00096space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00096_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00096space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00096_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00096space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00096_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00108
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00108space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00108_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00108space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00108_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00108space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00108_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00108space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00108_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00140
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00140space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00140_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00140space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00140_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00140space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00140_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00140space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00140_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00195
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00195space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00195_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00195space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00195_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00195space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00195_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00195space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00195_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00278
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00278space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00278_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00278space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00278_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00278space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00278_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00278space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00278_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00350
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00350space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00350_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00350space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00350_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00350space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00350_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00350space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00350_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00446
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00446space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00446_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00446space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00446_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00446space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00446_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00446space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00446_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00583
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00583space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00583_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00583space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00583_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00583space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00583_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00583space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00583_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS00833
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00833space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS00833_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00833space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS00833_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00833space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00833_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS00833space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS00833_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# DS01216
ln -s ${subject}_${session1}_${func_run1}_atlas-DS01216space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DS01216_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DS01216space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DS01216_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS01216space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS01216_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DS01216space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DS01216_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# HarvardOxfordcort
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-HOCPATh25_space-MNI152NLin6ASym_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-HOCPATh25_space-MNI152NLin6ASymMNI152NLin6ASym_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HOCPATh25_space-MNI152NLin6ASym_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HOCPATh25_space-MNI152NLin6ASym_desc-PearsonNilearn_correlations.tsv

# HarvardOxfordsub
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-HOSPATh25_space-MNI152NLin6ASym_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-HOSPATh25_space-MNI152NLin6ASymMNI152NLin6ASym_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HOSPATh25_space-MNI152NLin6ASym_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HOSPATh25_space-MNI152NLin6ASym_desc-PearsonNilearn_correlations.tsv

# JHUspace
ln -s ${subject}_${session1}_${func_run1}_atlas-JHUspace-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-JHU_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-JHUspace-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-JHU_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-JHUspace-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-JHU_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-JHUspace-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-JHU_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# Princetonvisual
ln -s ${subject}_${session1}_${func_run1}_atlas-Princetonvisual-topspace-MNI152NLin6res-2x2x2_desc-Mean_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-PrincetonvisualTop_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Princetonvisual-topspace-MNI152NLin6res-2x2x2_desc-ndmg_correlations.csv ${subject}_${session2}_${func_run2}_atlas-PrincetonvisualTop_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-2x2x2_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Princetonvisual-topspace-MNI152NLin6res-2x2x2_desc-PartialNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-PrincetonvisualTop_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Princetonvisual-topspace-MNI152NLin6res-2x2x2_desc-PearsonNilearn_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-PrincetonvisualTop_space-MNI152NLin6MNI152NLin6ASym_res-2x2x2_desc-PearsonNilearn_correlations.tsv

# regressors 
ln -s ${subject}_${session1}_${func_run1}_regressors.1D ${subject}_${session2}_${func_run2}_regressors.1D

# mean bold
ln -s ${subject}_${session1}_${func_run1}_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_sbref.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-preproc_bold.nii.gz ${subject}_${session2}_${func_run2}_desc-preproc_bold.nii.gz

# Motion Params 1D
ln -s ${subject}_${session1}_${func_run1}_dvars.1D ${subject}_${session2}_${func_run2}_desc-dvars_motion.1D

ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-jenkinson.1D ${subject}_${session2}_${func_run2}_desc-FDJenkinson_motion.1D

ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-power.1D ${subject}_${session2}_${func_run2}_desc-FDPower_motion.1D

ln -s ${subject}_${session1}_${func_run1}_max-displacement.1D ${subject}_${session2}_${func_run2}_desc-maxDisplacement_motion.1D

ln -s ${subject}_${session1}_${func_run1}_motion-params.txt ${subject}_${sesssion2}_${func_run2}_desc-motionParams_motion.txt

ln -s ${subject}_${session1}_${func_run1}_movement-parameters.1D ${subject}_${session2}_${func_run2}_desc-movementParameters_motion.1D

ln -s ${subject}_${session1}_${func_run1}_power-params.txt ${subject}_${session2}_${func_run2}_desc-powerParams_motion.txt

# Bold to template and template to bold
ln -s ${subject}_${session}_${func_run1}_from-bold_to-T1w_mode-image_desc-linear_xfm.mat ${subject}_${session2}_${func_run2}_from-bold_to-T1w_mode-image_desc-linear_xfm.mat

ln -s ${subject}_${session1}_${func_run1}_from-bold_to-template_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-bold_to-MNI152NLin6ASym_mode-image_xfm.nii.gz

# space T1w brain mask
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-bold_mask.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_desc-bold_mask.nii.gz

# space t1w mean bold 
ln -s ${subject}_${session1}_${func_run1}_space-T1w_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_space-T1w_sbref.nii.gz

# space desc preproc bold
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-preproc_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_desc-preproc_bold.nii.gz

# space template mean bold
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_sbref.nii.gz

#### left off this

# space template bold mask
ln -s ${subject}_${session1}_${func_run1}_space-template_res-derivative_desc-bold_mask.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_res-2mm_desc-bold_mask.nii.gz

# qc
ln -s ${subject}_${session1}_${func_run1}_bold-snr-qc.txt ${subject}_${session2}_${func_run2}_desc-boldSnr_quality.txt

echo "func symlink finished...."