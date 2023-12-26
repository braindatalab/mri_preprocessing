#!/bin/bash

# Environment variable $SUBJECTS_DIR needs to point to the freesurfer derivatives directory

list=$(ls $SUBJECTS_DIR)

#-------------------asegstats2table------------------#

# Store segmentation-specific measure option arguments (excluding volume) in variable 
declare -a s_arr=("Area_mm2" "nvoxels" "nvertices" "mean" "std" "max")

## Source aseg.stats 

# Fetch global stats for measure 'volume' with option --no-segno to exclude all regional structures
asegstats2table --subjects $list --meas volume --no-segno 4  5  7  8  10  11  12  13  14  15  16  17  18  24  26  28  30  31  43  44  46  47  49  50  51  52  53  54  58  60  62  63  72  77  78  79  80  81  82  85  251  252  253  254  255 --skip --tablefile aseg_asegstats_global.csv

# Fetch stats for measure 'volume' and use  --no-vol-extras  option
asegstats2table --subjects $list --meas volume --common-segs  --no-vol-extras --skip --tablefile aseg_asegstats_volume.csv

# Fetch stats for all remaining measures
for measure in "${s_arr[@]}"
do
   asegstats2table --subjects $list --meas $measure --common-segs --skip --tablefile aseg_asegstats_"$measure".csv
done

## Source wmparc.stats

# Fetch stats for measure 'volume' and use  --no-vol-extras  option
asegstats2table --subjects $list --statsfile wmparc.stats --meas volume --common-segs  --no-vol-extras --skip --tablefile wmparc_asegstats_volume.csv

# Fetch stats for all remaining measures
for measure in "${s_arr[@]}"
do
   asegstats2table --subjects $list --statsfile wmparc.stats --meas $measure --common-segs --skip --tablefile wmparc_asegstats_"$measure".csv
done

#-------------------aparcstats2table------------------#

# Store parcellation-specific measure option arguments in variable
declare -a p_arr=("area" "volume" "thickness" "thicknessstd" "thickness.T1" "meancurv" "gauscurv" "foldind" "curvind")

## Source lh.aparc.stats (Desikan/Killiany)

# Fetch stats for measures
for measure in "${p_arr[@]}"
do
   aparcstats2table --hemi lh --subjects $list --meas $measure --skip --tablefile lh_aparc_aparcstats_"$measure".csv
done

## Source rh.aparc.stats (Desikan/Killiany)

# Fetch stats for measures
for measure in "${p_arr[@]}"
do
   aparcstats2table --hemi rh --subjects $list --meas $measure --skip --tablefile rh_aparc_aparcstats_"$measure".csv
done

## Source lh.aparc.a2009.stats (Destrieux)

# Fetch stats for measures
for measure in "${p_arr[@]}"
do
   aparcstats2table --hemi lh --subjects $list --parc aparc.a2009s --meas $measure --skip --tablefile lh_a2009s_aparcstats_"$measure".csv
done

## Source rh.aparc.a2009.stats (Destrieux)

# Fetch stats for measures
for measure in "${p_arr[@]}"
do
   aparcstats2table --hemi rh --subjects $list --parc aparc.a2009s --meas $measure --skip --tablefile rh_a2009s_aparcstats_"$measure".csv
done
