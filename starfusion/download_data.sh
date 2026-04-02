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
    "${test_data_base_path}/genome/test_starfusion_rnaseq_1.fastq.gz|${DATA_DIR}|starfusion_sample.fastq.gz"
    "${test_data_base_path}/genome/minigenome.fa|${REF_DIR}|starfusion_ref.fa"
    "${test_data_base_path}/genome/minigenome.gtf|${REF_DIR}|starfusion_gtf.gtf"
    "${test_data_base_path}/genome/CTAT_HumanFusionLib.mini.dat.gz|${REF_DIR}|starfusion_CTAT_HumanFusionLib.mini.dat.gz"
    "${test_data_base_path}/genome/Pfam-A.hmm.gz|${REF_DIR}|starfusion_pfam.hmm.gz"
    "${test_data_base_path}/genome/test_starfusion_dfam.hmm|${REF_DIR}|starfusion_dfam.hmm"
    "${test_data_base_path}/genome/test_starfusion_dfam.hmm.h3f|${REF_DIR}|starfusion_dfam.hmm.h3f"
    "${test_data_base_path}/genome/test_starfusion_dfam.hmm.h3i|${REF_DIR}|starfusion_dfam.hmm.h3i"
    "${test_data_base_path}/genome/test_starfusion_dfam.hmm.h3m|${REF_DIR}|starfusion_dfam.hmm.h3m"
    "${test_data_base_path}/genome/test_starfusion_dfam.hmm.h3p|${REF_DIR}|starfusion_dfam.hmm.h3p"
    "${test_data_base_path}/rnaseq/test_starfusion.annotfilterrule.pm|${REF_DIR}|starfusion.annotfilterrule.pm"
)   

for entry in "${downloads[@]}"; do
    IFS='|' read -r file_url output_dir output_name <<< "$entry"
    echo "Downloading ${file_url##*/} to $output_dir/$output_name"
    curl "$file_url" -C - -o "$output_dir/$output_name"
done 
