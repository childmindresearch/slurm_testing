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

# desc preproc T1w
ln -s ${subject}_${session1}_desc-preproc_T1w.nii.gz ${subject}_${session2}_desc-preproc_T1w.nii.gz

# hemi L
ln -s ${subject}_${session1}_hemi-L_desc-surface_curv.curv ${subject}_${session2}_hemi-L_desc-surface_curv.curv
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMap_sulc.sulc ${subject}_${session2}_hemi-L_desc-surfaceMap_sulc.sulc
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMap_thickness.thickness ${subject}_${session2}_hemi-L_desc-surfaceMap_thickness.thickness
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMap_volume.volume ${subject}_${session2}_hemi-L_desc-surfaceMap_volume.volume
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMesh_pial.pial ${subject}_${session2}_hemi-L_desc-surfaceMesh_pial.pial
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMesh_smoothwm.smoothwm ${subject}_${session2}_hemi-L_desc-surfaceMesh_smoothwm.smoothwm
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMesh_sphere.sphere ${subject}_${session2}_hemi-L_desc-surfaceMesh_sphere.sphere
ln -s ${subject}_${session1}_hemi-L_desc-surfaceMesh_white.white ${subject}_${session2}_hemi-L_desc-surfaceMesh_white.white


ln -s ${subject}_${session1}_hemi-R_desc-surface_curv.curv ${subject}_${session2}_hemi-R_desc-surface_curv.curv
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMap_sulc.sulc ${subject}_${session2}_hemi-R_desc-surfaceMap_sulc.sulc
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMap_thickness.thickness ${subject}_${session2}_hemi-R_desc-surfaceMap_thickness.thickness
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMap_volume.volume ${subject}_${session2}_hemi-R_desc-surfaceMap_volume.volume
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMesh_pial.pial ${subject}_${session2}_hemi-R_desc-surfaceMesh_pial.pial
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMesh_smoothwm.smoothwm ${subject}_${session2}_hemi-R_desc-surfaceMesh_smoothwm.smoothwm
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMesh_sphere.sphere ${subject}_${session2}_hemi-R_desc-surfaceMesh_sphere.sphere
ln -s ${subject}_${session1}_hemi-R_desc-surfaceMesh_white.white ${subject}_${session2}_hemi-R_desc-surfaceMesh_white.white
ln -s ${subject}_${session1}_raw-average.mgz ${subject}_${session2}_rawAverage.mgz

find . -type l ! -exec test -e {} \; -print
find . -type l ! -exec test -e {} \; -exec rm {} \;

echo "anat symlink finished...."
echo "........................."
echo "Starting symlink for func directory...."

### FUNC ####
cd ..
cd func

# mean bold
ln -s ${subject}_${session1}_${func_run1}_desc-mean_bold.nii.gz ${subject}_${session2}_${func_run2}_sbref.nii.gz

ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-jenkinson.1D ${subject}_${session2}_${func_run2}_desc-FDJenkinson_motion.1D
ln -s ${subject}_${session1}_${func_run1}_framewise-displacement-power.1D ${subject}_${session2}_${func_run2}_desc-FDPower_motion.1D
ln -s ${subject}_${session1}_${func_run1}_motion-params.txt ${subject}_${session2}_${func_run2}_desc-motionParams_motion.txt
ln -s ${subject}_${session1}_${func_run1}_movement-parameters.1D ${subject}_${session2}_${func_run2}_desc-movementParameters_motion.1D
ln -s ${subject}_${session1}_${func_run1}_max-displacement.1D ${subject}_${session2}_${func_run2}_desc-maxDisplacement_motion.1D

find . -type l ! -exec test -e {} \; -print
find . -type l ! -exec test -e {} \; -exec rm {} \;

echo "func symlink finished...."