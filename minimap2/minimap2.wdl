version 1.2

import "../shared/ref_struct.wdl" as ref_struct

task minimap2 {
    input {
        File? reads_fq
        File? reads_bam
        File? index 
        ReferenceFiles ref
        Array[File]? interval_file
        Array[File]? known_sites
        String output_fmt
        String prefix
        Array[String]? args
        Int memory
        Int num_gpus
        Int num_cpus
        String container
    }

    String extension_bam = output_fmt
    String extension_bam_index = if output_fmt == "cram" then "crai" else "bai"

    String known_sites_command = if defined(known_sites) then
        sep(" ", prefix("--knownSites ", select_first([known_sites, []])))
        else ""

    String known_sites_output_cmd = if defined(known_sites) then
        "--out-recal-file ${prefix}.table"
        else ""
    
    String interval_file_command = if defined(interval_file) then
        sep(" ", prefix("--interval-file ", select_first([interval_file, []])))
        else ""

    String in_reads_command = if defined(reads_fq) then
            "--in-fq ~{reads_fq}"
        else if defined(reads_bam) then
            "--in-bam ~{reads_bam}"
        else ""

    String index_command = if defined(index) then
            "--index ~{index}"
        else ""

    command <<<
        set -e

        # Make sure the reference and index files are in the task's working directory
        ln -s ~{ref.fasta} $(basename ~{ref.fasta})
        ln -s ~{ref.fasta_fai} $(basename ~{ref.fasta_fai})
        for bwa_file in ~{sep(" ", ref.bwa_index)}; do
            ln -s "$bwa_file" $(basename "$bwa_file")
        done

        pbrun \
            minimap2 \
            --ref "$(basename ~{ref.fasta})" \
            ~{in_reads_command} \
            --out-bam ~{prefix}.~{extension_bam} \
            ~{known_sites_command} \
            ~{known_sites_output_cmd} \
            ~{interval_file_command} \
            ~{index_command} \
            --num-gpus ~{num_gpus} \
            --preserve-file-symlinks \
            ~{sep(" ", select_first([args, []]))}
    >>>

    output {
        File bam = "${prefix}.${extension_bam}"
        File bai = "${prefix}.${extension_bam}.${extension_bam_index}"
    }

    requirements {
        docker: container
        cpu: num_cpus
        memory: memory
        gpu: true
    }

    hints { 
        gpu: num_gpus 
    }

    meta { 
        author: "Gary Burnett (gburnett@nvidia.com)" 
        description: "NVIDIA Parabricks GPU accelerated Minimap2"
        outputs: {
            bam: "The output BAM/CRAM file",
            bai: "The output BAM/CRAM index file"
        }
    }

    parameter_meta {
        reads_fq: {description: "Input FASTQ file for alignment", category: "optional"}
        reads_bam: {description: "Input BAM file for alignment", category: "optional"}
        index: {description: "Pre-built minimap2 index file", category: "optional"}
        ref: {description: "Reference genome files (FASTA, index, and BWA index)", category: "required"}
        interval_file: {description: "Optional interval file for targeted regions (can be used multiple times)", category: "optional"}
        known_sites: {description: "Optional array of known variant sites for BQSR (can be used multiple times)", category: "optional"}
        output_fmt: {description: "Output format: 'bam' or 'cram'", category: "required"}
        prefix: {description: "Prefix for output files", category: "required"}
        args: {description: "Optional additional arguments for pbrun", category: "optional"}
        memory: {description: "Memory in GB", category: "required"}
        num_gpus: {description: "Number of GPUs to use", category: "required"}
        num_cpus: {description: "Number of CPU threads", category: "required"}
        container: {description: "Container image URI", category: "required"}
    }

}
