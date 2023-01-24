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

# surface atlas
ln -s ${subject}_${session1}_atlas-DesikanKilliany_space-fsLR_den-164k_dlabel.nii ${subject}_${session2}_atlas-DesikanKilliany_space-fsLR_den-164k_dlabel.nii
ln -s ${subject}_${session1}_atlas-DesikanKilliany_space-fsLR_den-32k_dlabel.nii ${subject}_${session2}_atlas-DesikanKilliany_space-fsLR_den-32k_dlabel.nii
ln -s ${subject}_${session1}_atlas-Destrieux_space-fsLR_den-164k_dlabel.nii ${subject}_${session2}_atlas-Destrieux_space-fsLR_den-164k_dlabel.nii
ln -s ${subject}_${session1}_atlas-Destrieux_space-fsLR_den-32k_dlabel.nii ${subject}_${session2}_atlas-Destrieux_space-fsLR_den-32k_dlabel.nii

# from t1w to template
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_desc-nonlinear_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_desc-nonlinear_xfm.nii.gz
ln -s ${subject}_${session1}_from-T1w_to-template_mode-image_xfm.nii.gz ${subject}_${session2}_from-T1w_to-MNI152NLin6ASym_mode-image_xfm.nii.gz

# from template to t1w
ln -s ${subject}_${session1}_from-template_to-T1w_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6ASym_to-T1w_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_from-template_to-T1w_mode-image_desc-nonlinear_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6ASym_to-T1w_mode-image_desc-nonlinear_xfm.nii.gz
ln -s ${subject}_${session1}_from-template_to-T1w_mode-image_xfm.nii.gz ${subject}_${session2}_from-MNI152NLin6ASym_to-T1w_mode-image_xfm.nii.gz

# T1w
ln -s ${subject}_${session1}_desc-restore_T1w.nii.gz ${subject}_${session2}_desc-restore_T1w.nii.gz
ln -s ${subject}_${session1}_desc-restore-brain_T1w.nii.gz ${subject}_${session2}_desc-restoreBrain_T1w.nii.gz
ln -s ${subject}_${session1}_desc-preproc_T1w.nii.gz ${subject}_${session2}_desc-preproc_T1w.nii.gz

# Hemisphere L surface
ln -s ${subject}_${session1}_hemi-L_desc-surface_curv.curv ${subject}_${session2}_hemi-L_desc-surface_curv.curv
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMap_sulc.sulc ${subject}_${session2}_hemi-L_desc-surfaceMap_sulc.sulc
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMap_thickness.thickness ${subject}_${session2}_hemi-L_desc-surfaceMap_thickness.thickness
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMap_volume.volume ${subject}_${session2}_hemi-L_desc-surfaceMap_volume.volume
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMesh_pial.pial ${subject}_${session2}_hemi-L_desc-surfaceMesh_pial.pial
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMesh_smoothwm.smoothwm ${subject}_${session2}_hemi-L_desc-surfaceMesh_smoothwm.smoothwm
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMesh_sphere.sphere ${subject}_${session2}_hemi-L_desc-surfaceMesh_sphere.sphere
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMesh_white.white ${subject}_${session2}_hemi-L_desc-surfaceMesh_white.white

# Hemisphere R surface
ln -s ${subject}_${session1}_hemi-R_desc-surface_curv.curv ${subject}_${session2}_hemi-R_desc-surface_curv.curv
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMap_sulc.sulc ${subject}_${session2}_hemi-R_desc-surfaceMap_sulc.sulc
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMap_thickness.thickness ${subject}_${session2}_hemi-R_desc-surfaceMap_thickness.thickness
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMap_volume.volume ${subject}_${session2}_hemi-R_desc-surfaceMap_volume.volume
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMesh_pial.pial ${subject}_${session2}_hemi-R_desc-surfaceMesh_pial.pial
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMesh_smoothwm.smoothwm ${subject}_${session2}_hemi-R_desc-surfaceMesh_smoothwm.smoothwm
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMesh_sphere.sphere ${subject}_${session2}_hemi-R_desc-surfaceMesh_sphere.sphere
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMesh_white.white ${subject}_${session2}_hemi-R_desc-surfaceMesh_white.white

# native template regressors 
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

# space template T1w
ln -s ${subject}_${session1}_space-T1w_desc-brain_mask.nii.gz ${subject}_${session2}_space-MNI152NLin6ASym_desc-brain_mask.nii.gz
ln -s ${subject}_${session1}_space-template_desc-head_T1w.nii.gz ${subject}_${session2}_space-MNI152NLin6ASym_desc-head_T1w.nii.gz
ln -s ${subject}_${session1}_space-template_desc-T1w_mask.nii.gz ${subject}_${session2}_space-MNI152NLin6ASym_desc-T1w_mask.nii.gz

# wmparc
ln -s ${subject}_${session1}_wmparc.mgz ${subject}_${session2}_wmparc.mgz

echo "anat symlink finished...."
echo "........................."
echo "Starting symlink for func directory...."

### FUNC ####
cd ..
cd func

# native space bold
ln -s ${subject}_${session1}_${func_run1}_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_desc-mean_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-preproc_bold.nii.gz ${subject}_${session2}_${func_run2}_desc-preproc_bold.nii.gz

# xfm
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-T1w_mode-image_desc-linear_xfm.mat ${subject}_${session2}_${func_run2}_from-bold_to-T1w_mode-image_desc-linear_xfm.mat
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-template_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-bold_to-template_mode-image_xfm.nii.gz
ln -s ${subject}_${session1}_${func_run1}_from-template_to-bold_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-template_to-bold_mode-image_xfm.nii.gz

# displacement
ln -s ${subject}_${session1}_${func_run1}_max-displacement.rms ${subject}_${session2}_${func_run2}_desc-maxDisplacement_motion.rms
ln -s ${subject}_${session1}_${func_run1}_rels-displacement.rms ${subject}_${session2}_${func_run2}_desc-relsDisplacement_motion.rms

# Motion Params 1D
ln -s ${subject}_${session1}_${func_run1}_movement-parameters.1D ${subject}_${session2}_${func_run2}_${func_run2}_desc-movementParameters_motion.1D

# space template bold
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-bold_mask.nii.gz ${subject}_${session2}_${func_run2}_space-MNI152NLin6ASym_desc-bold_mask.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-T1w_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_space-T1w_sbref.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-head_bold.nii.gz ${subject}_${session2}_${func_run2}_space-template_desc-head_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_space-template_sbref.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-template_desc-scout_bold.nii.gz ${subject}_${session2}_${func_run2}_space-template_desc-scout_bold.nii.gz

ln -s ${subject}_${session1}_${func_run1}_space-fsLR_den-32k_bold-dtseries.nii ${subject}_${session2}_${func_run2}_space-fsLR_den-32k_boldDtseries.nii

echo "func symlink finished...."