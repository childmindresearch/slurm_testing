#!/usr/bin/bash

[ ! -d  ./output_old_format ] && mkdir -p ./output_old_format

cp -r ./output ./output_old_format

pipeline="$(ls ./output/)"
subjects="$(ls ./output/${pipeline}/)"

for subject in ${subjects}; do
    subject_dir=./output/${pipeline}/${subject}
    [ ! -d  ${subject_dir}/ses-1 ] && mkdir -p ${subject_dir}/ses-1 
    cp -r ${subject_dir}/anat ${subject_dir}/ses-1
    cp -r ${subject_dir}/func ${subject_dir}/ses-1
    rm -r ${subject_dir}/anat
    rm -r ${subject_dir}/func
done
