#!/bin/bash 

# This script downloads the data files for deepvariant into $DATA_DIR
# It resumes interrupted file downloads and doesn't download files if they already exist

DATA_DIR=${PWD}/../test/fixtures/data
REF_DIR=${PWD}/../test/fixtures/ref

mkdir -p ${DATA_DIR}
mkdir -p ${REF_DIR}

# Each entry is "url|output_dir|output_name"
test_data_base_path="https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/homo_sapiens/genome"
downloads=(
    "${test_data_base_path}/minigenome.fa|${REF_DIR}|rnafq2bam_ref.fa"
    "${test_data_base_path}/minigenome.gtf|${REF_DIR}|rnafq2bam_gtf.gtf"
    "${test_data_base_path}/test_starfusion_rnaseq_1.fastq.gz|${DATA_DIR}|rnafq2bam_sample.fastq.gz"
)

for entry in "${downloads[@]}"; do
    IFS='|' read -r file_url output_dir output_name <<< "$entry"
    echo "Downloading ${file_url##*/} to $output_dir/$output_name"
    curl "$file_url" -C - -o "$output_dir/$output_name"
done 