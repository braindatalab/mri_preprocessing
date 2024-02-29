#!/bin/bash

# Assign input file (containing subjects with id and cohort) to variable
file=$1

source_path="user@client:/scratch/hbnetdata/derivatives/smriprep"
target_path="/project/t1images"

# Iterate over subject ids
for line in $(cat "$file"); do
	id=$(echo "${line}" | awk -F '-' '{print $1}')
	cohort=$(echo "${line}" | awk -F '-' '{print $2}')
	# Copy files
	# Normal case
	base="${source_path}/sub-${id}/anat/sub-${id}_acq-HCP_space-MNIPediatricAsym_cohort-"
	# Staten Island case
	#base="${source_path}/sub-${id}/anat/sub-${id}_space-MNIPediatricAsym_cohort-"
	scp "${base}${cohort}_desc-preproc_T1w.nii.gz" "${target_path}"
	scp "${base}${cohort}_label-GM_probseg.nii.gz" "${target_path}"
	scp "${base}${cohort}_label-WM_probseg.nii.gz" "${target_path}"
	scp "${base}${cohort}_label-CSF_probseg.nii.gz" "${target_path}"
done