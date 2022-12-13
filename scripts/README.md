# Scripts descriptions:

- Genome_Assembly_Hybrid.sh: Slurm script for running genome assemblies on CHPC. Modify variables in first section and submit.
  - Suggest running on single full node to allow gtdbtk classifier to finish, but if desired assemblies can usually be accomplished fairly quickly on shared nodes with only ~12 processors (default memory alloc). 

# Status

- Need to containerize.


# Nextflow in progress:

 - Main nextflow script should accept table with minimum info unique to each genome:
	- GenomeID (User-provided/isolate ID)
	- ONT FastQ (adapter trimmed and demultiplexed with guppy) DIRECTORY (allows for split files)(all files in directory will be concatenated)
	- Illumina FastQ DIRECTORY (allow for split files, assume read pairs)
	- Prokka options to genome (optional; correctly formatted - some not implemented)

 - Modules:
	- Trim (ONT and Illumina) and raw reports
	- Hybrid Assembly
	- (Illumina Only Assembly)
	- Prokka annotation(s)
	- GTDBtk classification
	- multiqc summary
	- GWAS
