#!/bin/bash

# Run 4 rclone copy commands in parallel

rclone copy --filter-from=~/filter.txt remote:/fcp-indi/data/Projects/HBN/MRI/Site-CBIC/ /scratch/hbnetdata/MRI/ &
rclone copy --filter-from=~/filter.txt remote:/fcp-indi/data/Projects/HBN/MRI/Site-CUNY/ /scratch/hbnetdata/MRI/ &
rclone copy --filter-from=~/filter.txt remote:/fcp-indi/data/Projects/HBN/MRI/Site-RU /scratch/hbnetdata/MRI/ &
rclone copy --filter-from=~/filter.txt remote:/fcp-indi/data/Projects/HBN/MRI/Site-SI /scratch/hbnetdata/MRI/ &
wait