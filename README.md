# Description

Scripts for hybrid bacterial genome assemblies using ONT and Illumina paired-end reads.

[scripts/GenomeAssembly_Hybrid.sh](scripts/Genome_Assembly_Hybrid.sh) Main Unicycler based hybrid assembly, prokka annotation, GTDBtk taxonomic call and quast assembly comparison.

[scripts/Genomes_gtdbtk.sh](scripts/genomes_gtdbtk.sh):  Accessory script running GTDBtk alone.

[scripts/guppy_basecall_demultiplex.sh](scripts/guppy_basecall_demultiplex.sh): Accessory slurm script for basecalling and demultiplexing from raw ONT fast5 files.

 - *nextflow in progress*.

# Usage:

Use scripts/Genome_Assembly_Hybrid.sh with input Illumina paired-end fastq files and ONT base-called and demultiplexed fastq files. Modify SBATCH directives and variables in first section as needed.

**NOTE**: Currently, these scripts require conda environments installed and miniconda3 module installed in ~/MyModules as recommended by CHPC. See here: https://www.chpc.utah.edu/documentation/software/python-anaconda.php 
