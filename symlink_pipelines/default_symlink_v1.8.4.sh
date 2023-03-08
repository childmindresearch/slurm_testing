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

# from symtemplate to T1w transforms
ln -s ${subject}_${session1}_from-symtemplate_to-T1w_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6Sym_to-T1w_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-symtemplate_to-T1w_mode-image_desc-nonlinear_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6Sym_to-T1w_mode-image_desc-nonlinear_xfm.nii.gz
ln -s ${subject}_${session1}_from-symtemplate_to-T1w_mode-image_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6Sym_to-T1w_mode-image_xfm.nii.gz

# from t1w to symtemplate
ln -s ${subject}_${session1}_from-T1w_to-symtemplate_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6Sym_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-symtemplate_mode-image_desc-nonlinear_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6Sym_mode-image_desc-nonlinear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-symtemplate_mode-image_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6Sym_mode-image_xfm.nii.gz

# from t1w to template
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_desc-nonlinear_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_desc-nonlinear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_xfm.nii.gz

# from template to t1w
ln -s ${subject}_${session1}_from-template_to-T1w_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6ASym_to-T1w_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-template_to-T1w_mode-image_desc-nonlinear_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6ASym_to-T1w_mode-image_desc-nonlinear_xfm.nii.gz
ln -s ${subject}_${session1}_from-template_to-T1w_mode-image_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6ASym_to-T1w_mode-image_xfm.nii.gz

# native space regressors
ln -s ${subject}_${session1}_label-CSF_desc-preproc_mask.nii.gz ${subject}_${session2}_label-CSF_desc-preproc_mask.nii.gz
ln -s ${subject}_${session1}_label-CSF_mask.nii.gz ${subject}_${session2}_label-CSF_mask.nii.gz
ln -s ${subject}_${session1}_label-CSF_probseg.nii.gz ${subject}_${session2}_label-CSF_probseg.nii.gz

ln -s ${subject}_${session1}_label-GM_desc-preproc_mask.nii.gz ${subject}_${session2}_label-GM_desc-preproc_mask.nii.gz
ln -s ${subject}_${session1}_label-GM_mask.nii.gz ${subject}_${session2}_label-GM_mask.nii.gz
ln -s ${subject}_${session1}_label-GM_probseg.nii.gz ${subject}_${session2}_label-GM_probseg.nii.gz

ln -s ${subject}_${session1}_label-WM_desc-preproc_mask.nii.gz ${subject}_${session2}_label-WM_desc-preproc_mask.nii.gz
ln -s ${subject}_${session1}_label-WM_mask.nii.gz ${subject}_${session2}_label-WM_mask.nii.gz
ln -s ${subject}_${session1}_label-WM_probseg.nii.gz ${subject}_${session2}_label-WM_probseg.nii.gz

# space template regressors
ln -s ${subject}_${session1}_space-template_label-CSF_mask.nii.gz ${subject}_${session2}_space-MNI152NLin6ASym_label-CSF_mask.nii.gz
ln -s ${subject}_${session1}_space-template_label-GM_mask.nii.gz ${subject}_${session2}_space-MNI152NLin6ASym_label-GM_mask.nii.gz
ln -s ${subject}_${session1}_space-template_label-WM_mask.nii.gz ${subject}_${session2}_space-MNI152NLin6ASym_label-WM_mask.nii.gz

# brain mask
ln -s ${subject}_${session1}_space-T1w_desc-brain_mask.nii.gz ${subject}_${session2}_space-MNI152NLin6ASym_desc-brain_mask.nii.gz

# desc preproc T1w
ln -s ${subject}_${session1}_desc-preproc_T1w.nii.gz ${subject}_${session2}_desc-preproc_T1w.nii.gz

echo "anat symlink finished...."
echo "........................."
echo "Starting symlink for func directory...."

### FUNC ####
cd ..
cd func

# templates

#aalmaskpad
ln -s ${subject}_${session1}_${func_run1}_atlas-aalmaskpad_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-aal_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-aalmaskpad_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-aal_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-aalmaskpad_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-aal_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-aalmaskpad_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-aal_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-aalmaskpad_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-aal_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-aalmaskpad_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-aal_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-aalmaskpad_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-aal_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-aalmaskpad_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-aal_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# AALspace
ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-AALspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-AAL_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Brodmann
ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Brodmannspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Brodmann_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# CAPRSC
ln -s ${subject}_${session1}_${func_run1}_atlas-CAPRSCspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-CAPRSC_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-CAPRSCspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-CAPRSC_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-CAPRSCspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-CAPRSC_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-CAPRSCspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-CAPRSC_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-CAPRSCspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CAPRSC_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-CAPRSCspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CAPRSC_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-CAPRSCspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CAPRSC_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-CAPRSCspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CAPRSC_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# CC200
ln -s ${subject}_${session1}_${func_run1}_atlas-CC200_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-CC200_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-CC200_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-CC200_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-CC200_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-CC200_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-CC200_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-CC200_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-CC200_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CC200_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-CC200_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CC200_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-CC200_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CC200_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-CC200_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CC200_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# CC400
ln -s ${subject}_${session1}_${func_run1}_atlas-CC400_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-CC400_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-CC400_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-CC400_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-CC400_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-CC400_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-CC400_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-CC400_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-CC400_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CC400_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-CC400_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CC400_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-CC400_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CC400_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-CC400_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-CC400_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# DesikanKlein
ln -s ${subject}_${session1}_${func_run1}_atlas-DesikanKleinspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DesikanKlein_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DesikanKleinspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DesikanKlein_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-DesikanKleinspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DesikanKlein_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DesikanKleinspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DesikanKlein_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-DesikanKleinspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DesikanKlein_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DesikanKleinspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DesikanKlein_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-DesikanKleinspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DesikanKlein_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DesikanKleinspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DesikanKlein_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Desikan
ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Desikanspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Desikan_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# DKT
ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-DKTspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-DKT_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Glasser
ln -s ${subject}_${session1}_${func_run1}_atlas-Glasserspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Glasser_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Glasserspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Glasser_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Glasserspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Glasser_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Glasserspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Glasser_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Glasserspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Glasser_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Glasserspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Glasser_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Glasserspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Glasser_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Glasserspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Glasser_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# HarvardOxfordcort
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordcortMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordcortMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordcortMaxprobThr25_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordcortMaxprobThr25_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordcortMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordcortMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordcortMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordcort-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordcortMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# HarvardOxfordsub
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordsubMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordsubMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordsubMaxprobThr25_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordsubMaxprobThr25_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordsubMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordsubMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordsubMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-HarvardOxfordsub-maxprob-thr25space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-HarvardOxfordsubMaxprobThr25_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# homaskpad
ln -s ${subject}_${session1}_${func_run1}_atlas-homaskpad_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-ho_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-homaskpad_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-ho_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-homaskpad_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-ho_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-homaskpad_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-ho_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-homaskpad_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-ho_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-homaskpad_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-ho_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-homaskpad_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-ho_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-homaskpad_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-ho_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Juelich
ln -s ${subject}_${session1}_${func_run1}_atlas-Juelichspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Juelich_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Juelichspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Juelich_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Juelichspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Juelich_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Juelichspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Juelich_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Juelichspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Juelich_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Juelichspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Juelich_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Juelichspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Juelich_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Juelichspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Juelich_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# MICCAI
ln -s ${subject}_${session1}_${func_run1}_atlas-MICCAIspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-MICCAI_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-MICCAIspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-MICCAI_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-MICCAIspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-MICCAI_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-MICCAIspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-MICCAI_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-MICCAIspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-MICCAI_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-MICCAIspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-MICCAI_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-MICCAIspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-MICCAI_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-MICCAIspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-MICCAI_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# PNASSmith09rsn10
ln -s ${subject}_${session1}_${func_run1}_atlas-PNASSmith09rsn10_desc-SpatReg-1_timeseries.txt ${subject}_${session2}_${func_run2}_atlas-PNAS_reg-default_desc-SpatReg_timeseries.txt
ln -s ${subject}_${session1}_${func_run1}_atlas-PNASSmith09rsn10_desc-SpatReg-2_timeseries.txt ${subject}_${session2}_${func_run2}_atlas-PNAS_reg-defaultNoGSR_desc-SpatReg_timeseries.txt

# rois3mm
ln -s ${subject}_${session1}_${func_run1}_atlas-rois3mm_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-rois3mm_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-rois3mm_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois3mm_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-rois3mm_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois3mm_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-rois3mm_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois3mm_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Schaefer1000
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer1000space-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p1000n17_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer1000space-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p1000n17_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer1000space-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p1000n17_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer1000space-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p1000n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer1000space-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p1000n17_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer1000space-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p1000n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer1000space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p1000n17_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer1000space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p1000n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Schaefer200
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer200space-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p200n17_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer200space-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p200n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer200space-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p200n17_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer200space-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p200n17_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer200space-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p200n17_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer200space-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p200n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer200space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p200n17_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer200space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p200n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Schaefer300
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer300space-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p300n17_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer300space-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p300n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer300space-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p300n17_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer300space-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p300n17_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer300space-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p300n17_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer300space-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p300n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer300space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p300n17_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer300space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p300n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Schaefer400
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer400space-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p400n17_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer400space-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p400n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer400space-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p400n17_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer400space-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p400n17_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer400space-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p400n17_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer400space-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p400n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer400space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p400n17_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Schaefer400space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Schaefer2018p400n17_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Slab907
ln -s ${subject}_${session1}_${func_run1}_atlas-Slab907space-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Slab907_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Slab907space-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Slab907_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Slab907space-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Slab907_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Slab907space-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Slab907_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Slab907space-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Slab907_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Slab907space-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Slab907_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Slab907space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Slab907_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Slab907space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Slab907_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Talairach
ln -s ${subject}_${session1}_${func_run1}_atlas-Talairachspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Talairach_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Talairachspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Talairach_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Talairachspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Talairach_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Talairachspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Talairach_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Talairachspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Talairach_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Talairachspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Talairach_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Talairachspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Talairach_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Talairachspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Talairach_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# ttmaskpad
ln -s ${subject}_${session1}_${func_run1}_atlas-ttmaskpad_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-tt_space-MNI152NLin6ASym_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-ttmaskpad_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-tt_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-ttmaskpad_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-tt_space-MNI152NLin6ASymMNI152NLin6ASym_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-ttmaskpad_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-tt_space-MNI152NLin6ASymMNI152NLin6ASym_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-ttmaskpad_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-tt_space-MNI152NLin6ASym_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-ttmaskpad_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-tt_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-ttmaskpad_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-tt_space-MNI152NLin6ASym_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-ttmaskpad_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-tt_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Yeo-17-liberalspace
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17-liberalspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Yeo17Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17-liberalspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Yeo17Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17-liberalspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Yeo17Liberal_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17-liberalspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Yeo17Liberal_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17-liberalspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo17Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17-liberalspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo17Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17-liberalspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo17Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17-liberalspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo17Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Yeo-17space
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17space-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Yeo17_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17space-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Yeo17_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17space-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Yeo17_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17space-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Yeo17_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17space-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo17_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17space-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo17_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo17_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-17space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo17_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Yeo-7-liberalspace
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7-liberalspace-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Yeo7Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7-liberalspace-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Yeo7Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7-liberalspace-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Yeo7Liberal_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7-liberalspace-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Yeo7Liberal_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7-liberalspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo7Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7-liberalspace-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo7Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7-liberalspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo7Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7-liberalspace-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo7Liberal_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# Yeo-7space
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7space-MNI152NLin6res-1x1x1_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Yeo7_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-Mean_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7space-MNI152NLin6res-1x1x1_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-Yeo7_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-Mean_timeseries.1D

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7space-MNI152NLin6res-1x1x1_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Yeo7_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-default_desc-ndmg_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7space-MNI152NLin6res-1x1x1_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-Yeo7_space-MNI152NLin6MNI152NLin6ASymMNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-ndmg_correlations.csv

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7space-MNI152NLin6res-1x1x1_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo7_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PartialNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7space-MNI152NLin6res-1x1x1_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo7_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PartialNilearn_correlations.tsv

ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo7_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-default_desc-PearsonNilearn_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-Yeo-7space-MNI152NLin6res-1x1x1_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-Yeo7_space-MNI152NLin6MNI152NLin6ASym_res-1x1x1_reg-defaultNoGSR_desc-PearsonNilearn_correlations.tsv

# regressors 
ln -s ${subject}_${session1}_${func_run1}_desc-1_regressors.1D ${subject}_${session2}_${func_run2}_reg-default_regressors.1D
ln -s ${subject}_${session1}_${func_run1}_desc-2_regressors.1D ${subject}_${session2}_${func_run2}_reg-defaultNoGSR_regressors.1D

ln -s ${subject}_${session1}_${func_run1}_desc-1_vmhc.nii.gz ${subject}_${session2}_${func_run2}_reg-default_vmhc.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-2_vmhc.nii.gz ${subject}_${session2}_${func_run2}_reg-defaultNoGSR_vmhc.nii.gz

# mean bold
ln -s ${subject}_${session1}_${func_run1}_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_sbref.nii.gz

# alff, falff, and reho
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-1_alff.nii.gz ${subject}_${session2}_${func_run2}_reg-default_desc-smZstd_alff.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-2_alff.nii.gz ${subject}_${session2}_${func_run2}_reg-defaultNoGSR_desc-smZstd_alff.nii.gz

ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-1_falff.nii.gz ${subject}_${session2}_${func_run2}_reg-default_desc-smZstd_falff.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-2_falff.nii.gz ${subject}_${session2}_${func_run2}_reg-defaultNoGSR_desc-smZstd_falff.nii.gz

ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-1_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-default_desc-smZstd_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-2_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-defaultNoGSR_desc-smZstd_reho.nii.gz

ln -s ${subject}_${session1}_${func_run1}_desc-zstd-1_alff.nii.gz ${subject}_${session2}_${func_run2}_reg-default_desc-zstd_alff.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-zstd-2_alff.nii.gz ${subject}_${session2}_${func_run2}_reg-defaultNoGSR_desc-zstd_alff.nii.gz

ln -s ${subject}_${session1}_${func_run1}_desc-zstd-1_falff.nii.gz ${subject}_${session2}_${func_run2}_reg-default_desc-zstd_falff.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-zstd-2_falff.nii.gz ${subject}_${session2}_${func_run2}_reg-defaultNoGSR_desc-zstd_falff.nii.gz

ln -s ${subject}_${session1}_${func_run1}_desc-zstd-1_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-default_desc-zstd_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-zstd-2_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-defaultNoGSR_desc-zstd_reho.nii.gz

# Motion Params 1D
ln -s ${subject}_${session1}_${func_run1}_dvars.1D ${subject}_${session2}_${func_run2}_desc-dvars_motion.1D

ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-jenkinson.1D ${subject}_${session2}_${func_run2}_desc-FDJenkinson_motion.1D
ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-power.1D ${subject}_${session2}_${func_run2}_desc-FDPower_motion.1D

ln -s ${subject}_${session1}_${func_run1}_max-displacement.1D ${subject}_${session2}_${func_run2}_desc-maxDisplacement_motion.1D

ln -s ${subject}_${session1}_${func_run1}_motion-params.txt ${subject}_${session2}_${func_run2}_desc-motionParams_motion.txt

ln -s ${subject}_${session1}_${func_run1}_movement-parameters.1D ${subject}_${session2}_${func_run2}_desc-movementParameters_motion.1D

ln -s ${subject}_${session1}_${func_run1}_power-params.txt ${subject}_${session2}_${func_run2}_desc-powerParams_motion.txt

# Bold to template and template to bold
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-symtemplate_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-bold_to-MNI152NLin6Sym_mode-image_xfm.nii.gz
ln -s ${subject}_${session}_${func_run1}_from-bold_to-T1w_mode-image_desc-linear_xfm.mat ${subject}_${session}_${func_run2}_from-bold_to-T1w_mode-image_desc-linear_xfm.mat
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-template_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-bold_to-MNI152NLin6ASym_mode-image_xfm.nii.gz
ln -s ${subject}_${session1}_${func_run1}_from-symtemplate_to-bold_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-MNI152NLin6Sym_to-bold_mode-image_xfm.nii.gz
ln -s ${subject}_${session1}_${func_run1}_from-template_to-bold_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-MNI152NLin6ASym_to-bold_mode-image_xfm.nii.gz

# space T1w brain mask
ln -s ${subject}_${session1}_${func_run1}_space-bold_desc-brain_mask.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_desc-bold_mask.nii.gz

# space t1w mean bold 
ln -s ${subject}_${session1}_${func_run1}_space-T1w_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_space-T1w_sbref.nii.gz

# space desc preproc bold
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-preproc-1_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-preproc_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-preproc-2_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-preproc_bold.nii.gz

# native desc preproc bold
ln -s ${subject}_${session1}_${func_run1}_desc-preproc-1_bold.nii.gz ${subject}_${session2}_${func_run2}_reg-default_desc-preproc_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-preproc-2_bold.nii.gz ${subject}_${session2}_${func_run2}_reg-defaultNoGSR_desc-preproc_bold.nii.gz

# degree centrality, lfcd, eigenvector centrality
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-binarized-sm-zstd-1_degree-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-smZstd_dcb.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-binarized-sm-zstd-2_degree-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-smZstd_dcb.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-binarized-sm-zstd-1_lfcd.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-smZstd_lfcdb.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-binarized-sm-zstd-2_lfcd.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-smZstd_lfcdb.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-binarized-zstd-1_degree-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-zstd_dcb.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-binarized-zstd-2_degree-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-zstd_dcb.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-binarized-zstd-1_lfcd.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-zstd_lfcdb.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-binarized-zstd-2_lfcd.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-zstd_lfcdb.nii.gz


ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-sm-zstd-1_degree-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-smZstd_dcw.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-sm-zstd-2_degree-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-smZstd_dcw.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-sm-zstd-1_lfcd.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-smZstd_lfcdw.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-sm-zstd-2_lfcd.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-smZstd_lfcdw.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-sm-zstd-1_eigen-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-smZstd_ecw.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-sm-zstd-2_eigen-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-smZstd_ecw.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-zstd-1_degree-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-zstd_dcw.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-zstd-2_degree-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-zstd_dcw.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-zstd-1_lfcd.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-zstd_lfcdw.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-zstd-2_lfcd.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-zstd_lfcdw.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-zstd-1_eigen-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-zstd_ecw.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-weighted-zstd-2_eigen-centrality.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-zstd_ecw.nii.gz

# space template alff, falff, reho
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-1_alff.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-smZstd_alff.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-2_alff.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-smZstd_alff.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-1_falff.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-smZstd_falff.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-2_falff.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-smZstd_falff.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-1_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-smZstd_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-2_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-smZstd_reho.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-1_alff.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-zstd_alff.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-2_alff.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-zstd_alff.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-1_falff.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-zstd_falff.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-2_falff.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-zstd_falff.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-1_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-default_desc-zstd_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-2_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-defaultNoGSR_desc-zstd_reho.nii.gz

# bold mask
ln -s ${subject}_${session1}_${func_run1}_space-template_res-derivative_desc-bold_mask.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_res-3mm_desc-bold_mask.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_sbref.nii.gz

# qc
ln -s ${subject}_${session1}_${func_run1}_bold-snr-qc.txt ${subject}_${session2}_${func_run2}_reg-default_desc-boldSnr_quality.txt

echo "func symlink finished...."