#!/bin/bash

#SBATCH --account=round-np
#SBATCH --partition=round-shared-np
#SBATCH -J nf_main
#SBATCH -n 2
#SBATCH -t 72:00:00
#SBATCH -o %x.outerror

# Launches nextflow job
module load nextflow/20.10

nextflow run project_nf.nf

