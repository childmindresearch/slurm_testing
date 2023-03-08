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

# T1w
ln -s ${subject}_${session1}_desc-brain_T1w.nii.gz ${subject}_${session2}_desc-brain_T1w.nii.gz
ln -s ${subject}_${session1}_desc-preproc_T1w.nii.gz ${subject}_${session2}_desc-preproc_T1w.nii.gz
ln -s ${subject}_${session1}_desc-reorient_T1w.nii.gz ${subject}_${session2}_desc-reorient_T1w.nii.gz

# symtemplate xfms
ln -s ${subject}_${session1}_from-symtemplate_to-T1w_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6Sym_to-T1w_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-symtemplate_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6Sym_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-symtemplate_mode-image_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6Sym_mode-image_xfm.nii.gz

# T1w xfms
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_xfm.nii.gz
ln -s ${subject}_${session1}_from-template_to-T1w_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6ASym_to-T1w_mode-image_desc-linear_xfm.nii.gz

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

# space template T1w
ln -s ${subject}_${session1}_space-T1w_desc-brain_mask.nii.gz ${subject}_${session2}_space-MNI152NLin6ASym_desc-brain_mask.nii.gz


echo "anat symlink finished...."
echo "........................."
echo "Starting symlink for func directory...."

### FUNC ####
cd ..
cd func

ln -s ${subject}_${session1}_${func_run1}_ ${subject}_${session2}_${func_run2}_

# atlas roi mean
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-Mean-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor1_desc-Mean1_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-Mean-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor2_desc-Mean2_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-Mean-3_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor3_desc-Mean3_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-Mean-4_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor1_desc-Mean4_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-Mean-5_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor2_desc-Mean5_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-Mean-6_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor3_desc-Mean6_timeseries.1D

# atlas roi ndmg
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-ndmg-1_correlations.csv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASymMNI152NLin6ASym_reg-Regressor1_desc-ndmg1_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-ndmg-2_correlations.csv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASymMNI152NLin6ASym_reg-Regressor2_desc-ndmg2_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-ndmg-3_correlations.csv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASymMNI152NLin6ASym_reg-Regressor3_desc-ndmg3_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-ndmg-4_correlations.csv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASymMNI152NLin6ASym_reg-Regressor1_desc-ndmg4_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-ndmg-5_correlations.csv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASymMNI152NLin6ASym_reg-Regressor2_desc-ndmg5_correlations.csv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-ndmg-6_correlations.csv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASymMNI152NLin6ASym_reg-Regressor3_desc-ndmg6_correlations.csv

# atlas roi partial nilearn
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PartialNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor1_desc-PartialNilearn1_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PartialNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor2_desc-PartialNilearn2_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PartialNilearn-3_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor3_desc-PartialNilearn3_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PartialNilearn-4_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor1_desc-PartialNilearn4_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PartialNilearn-5_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor2_desc-PartialNilearn5_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PartialNilearn-6_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor3_desc-PartialNilearn6_correlations.tsv

# atlas roi pearson nilearn
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PearsonNilearn-1_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor1_desc-PearsonNilearn1_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PearsonNilearn-2_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor2_desc-PearsonNilearn2_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PearsonNilearn-3_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor3_desc-PearsonNilearn3_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PearsonNilearn-4_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor1_desc-PearsonNilearn4_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PearsonNilearn-5_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor2_desc-PearsonNilearn5_correlations.tsv
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-PearsonNilearn-6_correlations.tsv ${subject}_${session2}_${func_run2}_atlas-rois_space-MNI152NLin6ASym_reg-Regressor3_desc-PearsonNilearn6_correlations.tsv

# atlas roi spatial reg
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-SpatReg-1_timeseries.txt ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor1_desc-SpatReg1_timeseries.txt
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-SpatReg-2_timeseries.txt ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor2_desc-SpatReg2_timeseries.txt
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-SpatReg-3_timeseries.txt ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor3_desc-SpatReg3_timeseries.txt
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-SpatReg-4_timeseries.txt ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor1_desc-SpatReg4_timeseries.txt
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-SpatReg-5_timeseries.txt ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor2_desc-SpatReg5_timeseries.txt
ln -s ${subject}_${session1}_${func_run1}_atlas-rois2mm_desc-SpatReg-6_timeseries.txt ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor3_desc-SpatReg6_timeseries.txt

# atlas roi voxel timeseries
ln -s ${subject}_${session1}_${func_run1}_sub-0025428_ses-1_task-rest_run-1_atlas-rois2mm_desc-Voxel-1_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor1_desc-Voxel1_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_sub-0025428_ses-1_task-rest_run-1_atlas-rois2mm_desc-Voxel-2_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor2_desc-Voxel2_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_sub-0025428_ses-1_task-rest_run-1_atlas-rois2mm_desc-Voxel-3_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor3_desc-Voxel3_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_sub-0025428_ses-1_task-rest_run-1_atlas-rois2mm_desc-Voxel-4_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor1_desc-Voxel4_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_sub-0025428_ses-1_task-rest_run-1_atlas-rois2mm_desc-Voxel-5_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor2_desc-Voxel5_timeseries.1D
ln -s ${subject}_${session1}_${func_run1}_sub-0025428_ses-1_task-rest_run-1_atlas-rois2mm_desc-Voxel-6_timeseries.1D ${subject}_${session2}_${func_run2}_atlas-rois_reg-Regressor3_desc-Voxel6_timeseries.1D

# regressors 1D
ln -s ${subject}_${session1}_${func_run1}_desc-1_regressors.1D ${subject}_${session2}_${func_run2}_reg-Regressor1_regressors.1D
ln -s ${subject}_${session1}_${func_run1}_desc-2_regressors.1D ${subject}_${session2}_${func_run2}_reg-Regressor2_regressors.1D
ln -s ${subject}_${session1}_${func_run1}_desc-3_regressors.1D ${subject}_${session2}_${func_run2}_reg-Regressor3_regressors.1D
ln -s ${subject}_${session1}_${func_run1}_desc-4_regressors.1D 
ln -s ${subject}_${session1}_${func_run1}_desc-5_regressors.1D 
ln -s ${subject}_${session1}_${func_run1}_desc-6_regressors.1D 

# motion
ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-jenkinson.1D ${subject}_${session2}_${func_run2}_desc-FDJenkinson_motion.1D
ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-power.1D ${subject}_${session2}_${func_run2}_desc-FDPower_motion.1D
ln -s ${subject}_${session1}_${func_run1}_max-displacement.1D ${subject}_${session2}_${func_run2}_desc-maxDisplacement_motion.1D
ln -s ${subject}_${session1}_${func_run1}_motion-params.txt ${subject}_${session2}_${func_run2}_desc-motionParams_motion.txt
ln -s ${subject}_${session1}_${func_run1}_movement-parameters.1D ${subject}_${session2}_${func_run2}_desc-movementParameters_motion.1D
ln -s ${subject}_${session1}_${func_run1}_power-params.txt ${subject}_${session2}_${func_run2}_desc-powerParams_motion.txt
ln -s ${subject}_${session1}_${func_run1}dvars.1D ${subject}_${session2}_${func_run2}_desc-dvars_motion.1D

# xfms
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-symtemplate_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-bold_to-MNI152NLin6Sym_mode-image_xfm.nii.gz
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-T1w_mode-image_desc-linear_xfm.mat ${subject}_${session2}_${func_run2}_from-bold_to-T1w_mode-image_desc-linear_xfm.mat
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-template_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-bold_to-MNI152NLin6ASym_mode-image_xfm.nii.gz

# native bold
ln -s ${subject}_${session1}_${func_run1}_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_desc-mean_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-motion_bold.nii.gz ${subject}_${session2}_${func_run2}_desc-motion_bold.nii.gz

# native desc preproc bold
ln -s ${subject}_${session1}_${func_run1}_desc-preproc-1_bold.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor1_desc-preproc1_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-preproc-2_bold.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor2_desc-preproc2_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-preproc-3_bold.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor3_desc-preproc3_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-preproc-4_bold.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor1_desc-preproc4_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-preproc-5_bold.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor2_desc-preproc5_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-preproc-6_bold.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor3_desc-preproc6_bold.nii.gz

# space preproc bold
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-preproc-1_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor1_desc-preproc1_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-preproc-2_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor2_desc-preproc2_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-preproc-3_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor3_desc-preproc3_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-preproc-4_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor1_desc-preproc4_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-preproc-5_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor2_desc-preproc5_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-preproc-6_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor3_desc-preproc6_bold.nii.gz

# desc sm4 bold
ln -s ${subject}_${session1}_${func_run1}_desc-sm4-1_bold.nii.gz ${subject}_${session2}_${func_run2}_

# native alff
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-1_alff.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor1_desc-smZstd_alff.nii.gz

# native falff

# native reho
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-1_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor1_desc-smZstd1_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-2_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor2_desc-smZstd2_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-3_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor3_desc-smZstd3_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-4_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor1_desc-smZstd4_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-5_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor2_desc-smZstd5_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-sm-zstd-6_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor3_desc-smZstd6_reho.nii.gz

ln -s ${subject}_${session1}_${func_run1}_desc-zstd-1_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor1_desc-zstd1_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-zstd-2_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor2_desc-zstd2_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-zstd-3_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor3_desc-zstd3_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-zstd-4_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor1_desc-zstd4_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-zstd-5_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor2_desc-zstd5_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-zstd-6_reho.nii.gz ${subject}_${session2}_${func_run2}_reg-Regressor3_desc-zstd6_reho.nii.gz

# space template reho
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-1_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor1_desc-smZstd1_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-2_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor2_desc-smZstd2_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-3_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor3_desc-smZstd3_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-4_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor1_desc-smZstd4_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-5_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor2_desc-smZstd5_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-sm-zstd-6_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor3_desc-smZstd6_reho.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-1_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor1_desc-zstd1_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-2_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor2_desc-zstd2_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-3_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor3_desc-zstd3_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-4_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor1_desc-zstd4_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-5_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor2_desc-zstd5_reho.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-zstd-6_reho.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_reg-Regressor3_desc-zstd6_reho.nii.gz

# space template bold mask
ln -s ${subject}_${session1}_${func_run1}_space-template_res-derivative_desc-bold_mask.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_res-2mm_desc-bold_mask.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-bold_mask.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_desc-bold_mask.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_sbref.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-T1w_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_space-T1w_sbref.nii.gz



echo "func symlink finished...."