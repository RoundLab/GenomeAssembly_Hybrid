#!/bin/bash

#SBATCH --account=round
#SBATCH --partition=notchpeak
#SBATCH -J gtdbtk
#SBATCH -N 1
#SBATCH -t 52:50:00
#SBATCH -D /uufs/chpc.utah.edu/common/home/u0210816/Projects/Zcomm/code/
#SBATCH -o /uufs/chpc.utah.edu/common/home/u0210816/Projects/Zcomm/code/genomes_gtdbtk.outerror

############ Parameters ###############################
ResultsDir=/uufs/chpc.utah.edu/common/home/u0210816/Projects/Zcomm/
# Space separated double quoted list of directories of genomes"
GenomeIDList="RDF6_Hybrid RDJ10_Hybrid RDK11_Hybrid RDO15_Hybrid"
NumProc=14
#######################################################
export GenomeIDList ResultsDir NumProc
#######################################################
module use ~/MyModules; ml miniconda3/latest
conda activate gtdbtk-2.1.1

cd ${ResultsDir}/genomes

for dir in $GenomeIDList
do 
    cd $dir
    mkdir -p gtdbtk_uni_normal
    gtdbtk classify_wf --genome_dir uni_normal/ --extension fasta --out_dir gtdbtk_uni_normal --force --cpus $NumProc --pplacer_cpus 1
    cd ../
done 
