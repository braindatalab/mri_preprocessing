#!/bin/bash

# Assign input file (containing subjects with id and cohort) to variable
file=$1

# Iterate over every line and add job to ts queue
for line in $(cat "$file"); do
	# Retrieve id and cohort
	id=$(echo "${line}" | awk -F '-' '{print $1}')
	cohort=$(echo "${line}" | awk -F '-' '{print $2}')

	# Add job to queue (use -ti and --rm options)
	ts docker run --rm\
   	 -v /scratch/hbnetdata/MRI:/data:ro \
   	 -v /scratch/hbnetdata/derivatives:/output \
   	 -v /scratch/hbnetdata/work:/work \
   	 -v $HOME/license.txt:/opt/freesurfer/license.txt \
   	 nipreps/smriprep:latest \
   	 /data /output \
   	 participant \
   	 --participant-label "${id}" \
   	 --nprocs 4 \
   	 --omp-nthreads 8 \
   	 --mem-gb 8 \
   	 --work-dir /work \
   	 --output-spaces MNIPediatricAsym:cohort-"${cohort}"
done
