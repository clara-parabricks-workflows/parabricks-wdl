#!/bin/bash 

# This script downloads the data files for deepvariant into $DATA_DIR
# It resumes interrupted file downloads and doesn't download files if they already exist

DATA_DIR=${PWD}/../test/fixtures/data
REF_DIR=${PWD}/../test/fixtures/ref

mkdir -p ${DATA_DIR}
mkdir -p ${REF_DIR}

# Each entry is "url|output_dir|output_name"
downloads=(
    "https://raw.githubusercontent.com/nf-core/test-datasets/methylseq/testdata/SRR389222_sub1.fastq.gz|${DATA_DIR}|fq2bam_sample.fastq.gz"
    "https://raw.githubusercontent.com/nf-core/test-datasets/methylseq/reference/genome.fa|${REF_DIR}|fq2bam_ref.fa"
)

for entry in "${downloads[@]}"; do
    IFS='|' read -r file_url output_dir output_name <<< "$entry"
    echo "Downloading ${file_url##*/} to $output_dir/$output_name"
    curl "$file_url" -C - -o "$output_dir/$output_name"
done
