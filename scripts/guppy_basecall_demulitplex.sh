#!/bin/bash

#SBATCH --account=notchpeak-gpu
#SBATCH --partition=notchpeak-gpu
#SBATCH -J basecall_guppy
#SBATCH --gres=gpu:2
#SBATCH -n 8
#SBATCH -t 7:50:00
#SBATCH -o /uufs/chpc.utah.edu/common/home/u0210816/III_tmp_projects/tmp_Carey_ONT_reads/code/guppy_basecall_demulitplex.outerror

# Script takes in fast5 files from ONT, basecalls and then demultiplexes to produce a single fastq for each barcode.
# Barcodes and adapters are trimmed from final output.
# User input required:
#  - Standard error / out file path in SBATCH -o above.
#  - Directory paths for raw fast5, scratch temp space, and results.
#
# Template here for NBD112-24 kit run on R9.4.1 version flowcell (which only has one config combo avail on minION)

################
RawFast5Dir=/uufs/chpc.utah.edu/common/home/u0210816/III_tmp_projects/tmp_Carey_ONT_reads/fast5/
ScratchDir=/scratch/general/vast/u0210816/Carrey_ONT/
ResDir=/uufs/chpc.utah.edu/common/home/u0210816/III_tmp_projects/tmp_Carey_ONT_reads/
# ONT kit for basecalling. Unquoted, no spaces. Use 'guppy_basecaller --print_workflows' to show possible values.
ONTkit=SQK-NBD111-24
# ONT Barcode kit. Unquoted, no spaces. ONT Barcode kit can be different or the same as kit. Must provide value for demultiplexing.
# use `guppy_barcoder --print_kits` to show possible combos.
ONTbckit=SQK-NBD112-24
ONTflowcell=FLO-FLG001
# Minimum quality score for filtering. Integer. minION ONT basecaller uses 9 by default.
MinQ=9
################
mkdir -p $RawDir $ScratchDir $ResDir
mkdir -p ${ScratchDir}/guppy_basecall ${ScratchDir}/guppy_demultiplex
mkdir -p ${ResDir}/guppy_demultiplex
##############

module load guppy/6.1.7_gpu

cp -r $RawFast5Dir/ ${ScratchDir}/raw

echo "TIME: guppy_basecaller Start: `date`"
guppy_basecaller --input_path ${ScratchDir}/raw --recursive --flowcell $ONTflowcell --kit $ONTkit -x auto --compress_fastq --save_path ${ScratchDir}/guppy_basecall --records_per_fastq 0 --min_qscore $MinQ --progress_stats_frequency 300
echo "TIME: guppy_basecaller End: `date`"

echo "TIME: guppy_demultiplex Start: `date`"
guppy_barcoder -i ${ScratchDir}/guppy_basecall/pass/ -s ${ScratchDir}/guppy_demultiplex --recursive --barcode_kits "$ONTbckit" -c configuration.cfg --compress_fastq --fastq_out -x auto -q 0 --trim_adapters --trim_barcodes --progress_stats_frequency 300
echo "TIME: guppy_demultiplex End: `date`"

# clean. Comment out rm commands as needed to retain intermediate files.
cp -r ${ScratchDir}/guppy_demultiplex/ ${ResDir}
rm -R ${ScratchDir}
