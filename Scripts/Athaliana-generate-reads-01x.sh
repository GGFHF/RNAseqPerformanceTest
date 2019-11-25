#!/bin/bash

#-------------------------------------------------------------------------------

# -- set -o nounset
# -- set -o verbose
# -- set -o xtrace

#-------------------------------------------------------------------------------

if [ -n "$*" ]; then echo 'This script has not parameters.'; exit 1; fi

#-------------------------------------------------------------------------------

SIMNGS_DIR=$APP/simNGS/bin
NGSHELPER_DIR=$TRABAJO/NGShelper
export PATH=$SIMNGS_DIR:$PATH

COVERAGE=01
VERSION=01

OUTPUT_DIR=$TRABAJO/Athaliana/reads-${COVERAGE}x-v${VERSION}
TRANSCRIPTOME_FILE=$DAT/ArabidopsisThaliana/GCF_000001735.3_TAIR10_rna.fna
LIBRARY_FILE=library.fasta
READ_FILE=reads
READ_FILE_1=${READ_FILE}_end1.fq
READ_FILE_2=${READ_FILE}_end2.fq
FIXED_READ_FILE_1=fixed_${READ_FILE}_end1.fq
FIXED_READ_FILE_2=fixed_${READ_FILE}_end2.fq
COVARIANCE_FILE=$APP/simNGS/data/s_3_4x.runfile
SIMLIBRARY_ERROR_FILE=simlibrary_errors.txt
SIMNGS_ERROR_FILE=simngs_errors.txt

if [ ! -d $OUTPUT_DIR ]; then mkdir $OUTPUT_DIR; else rm -f $OUTPUT_DIR/*; fi

cd $OUTPUT_DIR

#-------------------------------------------------------------------------------

echo '**************************************************'
echo "Building the library ..."

# --simLibrary \
# --    --coverage=2.0 \
# --    --nfragments=1 \
# --    --strand=random \
# --    --bias=0.5 \
# --    --mutate=1e-5:1e-6:1e-4 \
# --    --insert=400 \
# --    --readlen=45 \
# --    --cov=0.055 \
# --    --output=fasta \
# --    $TRANSCRIPTOME_FILE \
# --    >$LIBRARY_FILE \
# --    2>$SIMLIBRARY_ERROR_FILE
simLibrary \
    --coverage=$COVERAGE \
    --strand=same \
    --bias=0.5 \
    --mutate=0:0:0 \
    --insert=400 \
    --readlen=100 \
    --cov=0.055 \
    --output=fasta \
    $TRANSCRIPTOME_FILE \
    >$LIBRARY_FILE \
    2>$SIMLIBRARY_ERROR_FILE
if [ $? -ne 0 ]; then echo 'Script ended with errors.'; exit 1; fi

echo 'The library is built.'

#-------------------------------------------------------------------------------

echo '**************************************************'
echo 'Generating reads from the library ...'

simNGS \
    --illumina \
    --paired=paired \
    --output=fastq \
    --outfile=$READ_FILE \
    $COVARIANCE_FILE \
    $LIBRARY_FILE \
    2>$SIMNGS_ERROR_FILE
if [ $? -ne 0 ]; then echo 'Script ended with errors.'; exit 1; fi

echo 'The read files are generated.'

#-------------------------------------------------------------------------------

echo '**************************************************'
echo 'Fixing sequence identifier records in read files ...'

python3 $NGSHELPER_DIR/simNGS-read-fixing.py --readfile=$READ_FILE_1 --filenum=1
if [ $? -ne 0 ]; then echo 'Script ended with errors.'; exit 1; fi

python3 $NGSHELPER_DIR/simNGS-read-fixing.py --readfile=$READ_FILE_2 --filenum=2
if [ $? -ne 0 ]; then echo 'Script ended with errors.'; exit 1; fi

echo 'The records are fixed.'

#-------------------------------------------------------------------------------

echo '**************************************************'
echo 'Removing read files with original sequence identifier records ...'

rm $READ_FILE_1
if [ $? -ne 0 ]; then echo 'Script ended with errors.'; exit 1; fi

rm $READ_FILE_2
if [ $? -ne 0 ]; then echo 'Script ended with errors.'; exit 1; fi

echo 'The records are removed.'

#-------------------------------------------------------------------------------

echo '**************************************************'
echo 'Compressing library and read files ...'

gzip $LIBRARY_FILE
if [ $? -ne 0 ]; then echo 'Script ended with errors.'; exit 1; fi

gzip $FIXED_READ_FILE_1
if [ $? -ne 0 ]; then echo 'Script ended with errors.'; exit 1; fi

gzip $FIXED_READ_FILE_2
if [ $? -ne 0 ]; then echo 'Script ended with errors.'; exit 1; fi

echo 'The files are compressed.'

#-------------------------------------------------------------------------------

# End
echo '**************************************************'
exit 0

#-------------------------------------------------------------------------------
