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

subject_list="$(ls)"
if [[ ${subject_list} != *"sub-"* ]];then
    prefix="sub-"
    sub_no_prefix=${subject#"$prefix"}
    echo "subject no prefix $sub_no_prefix"
    cd "$sub_no_prefix"/ses-1
else
    cd ${subject}/ses-1
fi

echo "Starting symlink for func directory...."

### FUNC ####
cd func

ln -s ${subject}_${session1}_${func_run1}_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_desc-mean_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_desc-preproc_bold.nii.gz ${subject}_${session2}_${func_run2}_desc-preproc_bold.nii.gz

ln -s ${subject}_${session1}_${func_run1}_dvars.1D ${subject}_${session2}_${func_run2}_desc-dvars_motion.1D
ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-jenkinson.1D ${subject}_${session2}_${func_run2}_desc-FDJenkinson_motion.1D
ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-power.1D ${subject}_${session2}_${func_run2}_desc-FDPower_motion.1D
ln -s ${subject}_${session1}_${func_run1}_max-displacement.rms ${subject}_${session2}_${func_run2}_desc-maxDisplacement_motion.rms
ln -s ${subject}_${session1}_${func_run1}_motion-params.txt ${subject}_${session2}_${func_run2}_desc-motionParams_motion.txt
ln -s ${subject}_${session1}_${func_run1}_movement-parameters.1D ${subject}_${session2}_${func_run2}_desc-movementParameters_motion.1D
ln -s ${subject}_${session1}_${func_run1}_power-params.txt ${subject}_${session2}_${func_run2}_desc-powerParams_motion.txt
ln -s ${subject}_${session1}_${func_run1}_rels-displacement.rms ${subject}_${session2}_${func_run2}_desc-relsDisplacement_motion.rms

# xfms
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-EPItemplate_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-bold_to-template_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-EPItemplate_mode-image_desc-nonlinear_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-bold_to-template_mode-image_desc-nonlinear_xfm.nii.gz
ln -s ${subject}_${session1}_${func_run1}_from-bold_to-EPItemplate_mode-image_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-bold_to-template_mode-image_xfm.nii.gz
ln -s ${subject}_${session1}_${func_run1}_from-EPItemplate_to-bold_mode-image_desc-linear_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-template_to-bold_mode-image_desc-linear_xfm.nii.gz
ln -s ${subject}_${session1}_${func_run1}_from-EPItemplate_to-bold_mode-image_desc-nonlinear_xfm.nii.gz ${subject}_${session2}_${func_run2}_from-template_to-bold_mode-image_desc-nonlinear_xfm.nii.gz

# regressors
ln -s ${subject}_${session1}_${func_run1}_regressors.1D ${subject}_${session2}_${func_run2}_regressors.1D

# space template
ln -s ${subject}_${session1}_${func_run1}_space-EPItemplate_desc-bold_mask.nii.gz ${subject}_${session2}_${func_run2}_space-template_desc-bold_mask.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-EPItemplate_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_space-template_desc-mean_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_space-EPItemplate_desc-preproc_bold.nii.gz ${subject}_${session2}_${func_run2}_space-template_desc-preproc_bold.nii.gz
ln -s ${subject}_${session1}_${func_run1}_ ${subject}_${session2}_${func_run2}_
ln -s ${subject}_${session1}_${func_run1}_ ${subject}_${session2}_${func_run2}_

find . -type l ! -exec test -e {} \; -print
find . -type l ! -exec test -e {} \; -exec rm {} \;
echo "func symlink finished...."