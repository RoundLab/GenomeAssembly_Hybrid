#!/bin/bash

#SBATCH --account=
#SBATCH --partition=
#SBATCH -J
#SBATCH -N 1
#SBATCH -t 24:50:00
#SBATCH -o

# version: 2022.11.02

# Requires:
# (conda envs are assumed to have been installed per CHPC recommendations with miniconda3 module in ~/MyModules/)
#     - nanofilt (conda env with nanoplot also installed) for ONT read filtering (doesn't actually do much but creates plots of input and filt and useful if no quality filter was put on initial basecalling)
#     - trim_galore (chpc module)
#     - unicycler conda env (should already have spades installed in it)
#     - prokka (conda env)
#     - quast (conda env)

############ Parameters ###############################
# Short unquoted ID (no spaces) for genome. Used in file outputs naming AND top level directory of all other directory inputs below.
GenomeID=
# Illumina raw reads DIRECTORY (must contain only the reads for this genome) (required)
## Currently, must be named ending in _1.fq.gz and _2.fq.gz. Can contain multiple fastq files per each read.
IllRawDir=
# ONT reads DIRECTORY with basecalled and demultiplexed (if applicable) reads in fastq format. (required)
## Can contain multiple fastqs, but currently must end in "*.fastq.gz"
ONTRawDir=
# Location to save resulting assembly. (required)
ResultsDir=
# A scratch directory for intermedieate files, usually in scratch space in CHPC gen environment (required)
ScratchDir=
# Directory to save trimmed raw sequences, if desired (optional; leave blank to NOT save trimmed raw seqs)
TrimDir=
# Number of processors to use. For compatibility with shared node job submissions where some programs will autodetect ALL processors on node and set this to high. (required)
NumProc=14
# Spades max memory In Gb. Spades uses 512 Mb per thread max normally according to docs, with 250 Gb max total by default. Just set max available here, bacteria likely won't be all used and actual consumption has more to do with data structure.
SpadesMem=42
# Extra options to Prokka (in double quotes). (optional; Leave blank if none)
ProkkaOpts=
# Should pipeline run Illumina only assembly as well? (for comparing with and without long reads) [TRUE / FALSE]
IlluminaOnly=TRUE
#######################################################
export GenomeID RawDir ResultsDir ScratchDir NumProc SpadesMem ProkkaOpts TrimDir IlluminaOnly ONTRawDir
mkdir -p ${ResultsDir}/${GenomeID}
mkdir -p ${ScratchDir}/${GenomeID}
module load trim_galore/0.6.6
#######################################################

# Step 0: Read concatenation. (Novogene sends 2 seq files per sample). As opposed to a single input file, we just concatenate (and shorten name) and send to scratch space in one command.
## Illumina reads
cat ${IllRawDir}/*_1.fq.gz > ${ScratchDir}/${GenomeID}/${GenomeID}_1.fq.gz
cat ${IllRawDir}/*_2.fq.gz > ${ScratchDir}/${GenomeID}/${GenomeID}_2.fq.gz

## ONT reads
cp ${ONTRawDir}/*.fastq.gz ${ScratchDir}/${GenomeID}/${GenomeID}_ONT.fq.gz

# Step 0: File name and zip check, renaming if needed to just _1.fq.gz to be consistent with SRA pairs.
## Illumina
## ONT

cd ${ScratchDir}/${GenomeID}

# Step 1: Read QC and trimming:
## Illumina
echo "TIME:START trim_galore: `date`"
mkdir -p trim/
for f in *_1.fq.gz
    do
    trim_galore --cores 4 --paired --fastqc --basename ${GenomeID} --length 20 -q 20 -o trim/ ${f} ${f%_1.fq.gz}_2.fq.gz
done
echo "TIME:END trim_galore: `date`"

# ONT
echo "TIME:START nanofilt: `date`"
mkdir -p trim/
module purge; module use ~/MyModules; ml miniconda3/latest
conda activate nanofilt
for f in *_ONT.fq.gz; do gunzip -c $f | NanoFilt -q 10 -l 200 | pigz -p $NumProc > trim/${f}; done
echo "TIME:END nanofilt: `date`"
NanoPlot -t $NumProc --color purple --outdir nanoplot --prefix Raw_ --fastq ${GenomeID}_ONT.fq.gz --tsv_stats
NanoPlot -t $NumProc --color purple --outdir nanoplot --prefix NanoFilt_ --fastq trim/${GenomeID}_ONT.fq.gz --tsv_stats
conda deactivate

# Step 2: assembly
conda activate unicycler
## Illumina only
# Here, trying to recapitulate simialr parameters as uncicylcer would use for spades of short reads only. Not sure we can alter parameters of unicycler's spades call, but some things like cov_cutoff are not ideal there probably b/c of need to include long reads.
if [[ $IlluminaOnly = TRUE ]]
then
  echo "TIME:START spades: `date`"
  mkdir -p tmp_spades/; mkdir -p spades_IlluminaOnly
  mkdir -p spades_IlluminaOnly/
  spades.py -1 trim/${GenomeID}_val_1.fq.gz -2 trim/${GenomeID}_val_2.fq.gz --isolate -t $NumProc -m $SpadesMem --tmp-dir ${ScratchDir}/${GenomeID}/tmp_spades/ -o spades_IlluminaOnly/
  rm -R tmp_spades/
  echo "TIME:END spades: `date`"
fi

## w/ ONT reads
echo "TIME:START unicycler assembly: `date`"
for mode in conservative normal bold
  do
  unicycler -t $NumProc --keep 2 --mode $mode -o uni_${mode} -l trim/${GenomeID}_ONT.fq.gz -1 trim/${GenomeID}_val_1.fq.gz -2 trim/${GenomeID}_val_2.fq.gz
done
echo "TIME:END unicycler assembly: `date`"

conda deactivate

# Step 3: Prokka annotation of hybrid assembly only - normal mode by default
echo "TIME:START prokka: `date`"
conda activate prokka
prokka --cpus $NumProc --compliant --force --outdir prokka_uni_normal --prefix ${GenomeID} --rfam ${ProkkaOpts} uni_normal/assembly.fasta
echo "TIME:END prokka: `date`"
conda deactivate

# Step 4: Quast to comapre assemblies (note my quast conda env has the silva db and busco dbs run 'quast-download-silva','quast-download-busco')
#  - I run this on the annotated normal mode hybrid assembly specifying the annotation outputs first, then on the
# - Note min conting length of 200 is required for compliant genbank submissions (see prokka options) so is minimum given to quast to compare as well  (-m 200)

conda activate quast
echo "TIME:START quast: `date`"
quast.py uni_normal/assembly.fasta -b -o quast_annotated -g prokka_uni_normal/${GenomeID}.gff -m 200 -t ${NumProc} --no-sv --pe1 trim/${GenomeID}_val_1.fq.gz --pe2 trim/${GenomeID}_val_2.fq.gz --nanopore trim/${GenomeID}_ONT.fq.gz

if [[ $IlluminaOnly=TRUE ]]
then
  quast.py spades_IlluminaOnly/contigs.fasta uni_normal/assembly.fasta uni_bold/assembly.fasta uni_conservative/assembly.fasta \
  --labels Illumina_Only,Hybrid_normal,Hybrid_bold,Hybrid_conservative -b -o quast_compare -m 200 -t ${NumProc} --no-sv \
  --pe1 trim/${GenomeID}_val_1.fq.gz --pe2 trim/${GenomeID}_val_2.fq.gz --nanopore trim/${GenomeID}_ONT.fq.gz \
  -g prokka_uni_normal/${GenomeID}.gff -r uni_normal/assembly.fasta
else
  quast.py uni_normal/assembly.fasta uni_bold/assembly.fasta uni_conservative/assembly.fasta \
  --labels Hybrid_normal,Hybrid_bold,Hybrid_conservative -b -o quast_compare -m 200 -t ${NumProc} --no-sv \
  --pe1 trim/${GenomeID}_val_1.fq.gz --pe2 trim/${GenomeID}_val_2.fq.gz --nanopore trim/${GenomeID}_ONT.fq.gz \
  -g prokka_uni_normal/${GenomeID}.gff -r uni_normal/assembly.fasta
fi
echo "TIME:END quast: `date`"
conda deactivate

# Step 5: GTDBtk
# this could use the input gene calls from prokka instead of recalling, but seems to be some problems wiht how 2.1.1 is creating softlinks when this mode (wiht --gene) is invoked.
# Pplacer uses a ton of memory and will report (incorreclty according to docs) it needs 120Gb x nproc, so keep pplacer proc to 1
mkdir -p gtdbtk_uni_normal
conda activate gtdbtk-2.1.1
echo "TIME:END gtdbtk: `date`"
gtdbtk classify_wf --genome_dir uni_normal/ --extension fasta --out_dir gtdbtk_uni_normal --force --cpus $NumProc --pplacer_cpus 1
echo "TIME:END gtdbtk: `date`"
conda deactivate

# Step 6: Multiqc
module purge; module load multiqc/1.12
multiqc -o multiqc -i ${GenomeID}_multiqc -f --quiet ./

# Step 6: copy key results to working directory and cleanup

## Minimal, with trimmed reads save if directory given:
mkdir -p ${ResultsDir}/${GenomeID}/
cp -r prokka_uni_normal/ ${ResultsDir}/${GenomeID}/
cp -r multiqc/ ${ResultsDir}/${GenomeID}/
cp -r nanoplot/ ${ResultsDir}/${GenomeID}/
if [ $IlluminaOnly = TRUE ]; then cp quast_compare/ ${ResultsDir}/${GenomeID}/; fi
cp -r quast_annotated/ ${ResultsDir}/${GenomeID}/
mkdir -p ${ResultsDir}/${GenomeID}/uni_normal
cp uni_normal/unicycler.log ${ResultsDir}/${GenomeID}/uni_normal/
cp uni_normal/assembly.* ${ResultsDir}/${GenomeID}/uni_normal/
if [[ -d $TrimDir ]]
then
  mkdir -p ${TrimDir}/${GenomeID}
  cp trim/*.fq.gz ${TrimDir}/${GenomeID}
fi

# Cleanup (always, at least remove the copied over raw seqs)
rm ${ScratchDir}/${GenomeID}/${GenomeID}_1.fq.gz; rm ${ScratchDir}/${GenomeID}/${GenomeID}_2.fq.gz; rm ${ScratchDir}/${GenomeID}/${GenomeID}_ONT.fq.gz
# rm -R ${ScratchDir}/${GenomeID}
