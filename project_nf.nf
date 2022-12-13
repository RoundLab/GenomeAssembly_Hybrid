#!/us/bin/env nextflow

nextflow.enable.dsl=2

/*
All inputs through params at first
*/

params.ONTkit
params.ONTbckit
params.ONTflowcell
params.ONTminq
params.SCRATCH
params.ResDir
params.InputFAST5ONTDir=
params.InputFASTQIlluminaDir
params.SaveTrim
params.IlluminaOnly
params.ProkkaOpts
params.GenomeMetadata



/* Assembly variables in bash script:
GenomeID=RDO15_Hybrid
IllRawDir=/uufs/chpc.utah.edu/common/home/round-group3/raw_illumina_seq/2204_NG_BactGenomes/usftp21.novogene.com/raw_data/RDO15/
ONTRawDir=/uufs/chpc.utah.edu/common/home/round-group2/Minion_rawreads/BacGenomes2205/BacGenomes2205_MultiplexGroup1/BacGenomes2205_MultiplexGroup1/20220518_1257_MN33492_FAP73000_aef61014/guppy_demultiplex_BC_Adapt_trim/barcode05/
ResultsDir=/uufs/chpc.utah.edu/common/home/u0210816/Projects/Zcomm/genomes/
ScratchDir=/scratch/general/lustre/u0210816/bactgenomes/
# Directory to save trimmed raw sequences, if desired (optional; leave blank to NOT save trimmed raw seqs)
TrimDir=
NumProc=14
# Spades max memory In Gb. Spades uses 512 Mb per thread max normally according to docs, with 250 Gb max total by default. Just set max available here, bacteria likely won't be all used and actual consumption has more to do with data structure rather.
SpadesMem=42
# Extra options to Prokka (in double quotes). Leave blank if none.
ProkkaOpts=
# Should pipeline run Illumina only assembly as well? (for comparing with and without long reads) [TRUE / FALSE]
IlluminaOnly=TRUE
*/
