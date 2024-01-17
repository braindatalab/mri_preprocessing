#!/bin/bash

# Assign input file (containing subjects with id and cohort) to variable
file=$1

source_path="/scratch/hbndetdata/MRI/derivatives/sMRIprep"
target_path="/scratch/hbndetdata/brain-images"

declare -a files=(\
"_acq-HCP_desc-brain_mask.nii.gz"\
"_acq-HCP_desc-preproc_T1w.nii.gz"\
"_acq-HCP_label-GM_probseg.nii.gz"\
"_acq-HCP_label-WM_probseg.nii.gz"\
"_acq-HCP_label-CSF_probseg.nii.gz"\
"_acq-HCP_space-MNIPediatricAsym_cohort-"*"_desc-preproc_T1w.nii.gz"\
"_acq-HCP_space-MNIPediatricAsym_cohort-"*"_label-GM_probseg.nii.gz"\
"_acq-HCP_space-MNIPediatricAsym_cohort-"*"_label-WM_probseg.nii.gz"\
"_acq-HCP_space-MNIPediatricAsym_cohort-"*"_label-CSF_probseg.nii.gz"\
)

# Iterate over subject ids
for id in $(cat "$file"); do
	# Copy files
	for f in "${files[@]}"; do
		$(cp "$source_path"/sub-"$id"/anat/sub-"$id""$f" "$target_path")
	done
done
