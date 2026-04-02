#!/bin/bash 

# This script downloads the data files for deepvariant into $DATA_DIR
# It resumes interrupted file downloads and doesn't download files if they already exist

DATA_DIR=${PWD}/../test/fixtures/data
REF_DIR=${PWD}/../test/fixtures/ref

mkdir -p ${DATA_DIR}
mkdir -p ${REF_DIR}

# Each entry is "url|output_dir|output_name"
test_data_base_path="https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/homo_sapiens"
downloads=(
    "${test_data_base_path}/illumina/bam/test2.paired_end.recalibrated.sorted.bam|${DATA_DIR}|deepvariant_sample.bam"
    "${test_data_base_path}/genome/chr21/sequence/genome.fasta|${REF_DIR}|deepvariant_ref.fasta"
)

for entry in "${downloads[@]}"; do
    IFS='|' read -r file_url output_dir output_name <<< "$entry"
    echo "Downloading ${file_url##*/} to $output_dir/$output_name"
    curl "$file_url" -C - -o "$output_dir/$output_name"
done
