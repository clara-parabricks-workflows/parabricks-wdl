version 1.2

import "../shared/ref_struct.wdl" as ref_struct

task fq2bam {
    input {
        Array[File] reads
        ReferenceFiles ref
        Array[File]? interval_file
        Array[File]? known_sites
        String output_fmt
        Boolean single_ended
        Boolean qc_metrics
        Boolean duplicate_metrics
        String prefix
        Array[String]? args
        Int memory
        Int num_gpus
        Int num_cpus
        String container
    }

    # Array[File] reads = read_lines(samplesheet)
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

    String in_fq_command = if single_ended then 
        sep(" ", prefix("--in-se-fq ", reads))
        else "--in-fq ${sep(" ", reads)}"

    String qc_metrics_command = if qc_metrics then 
        "--out-qc-metrics-dir ${prefix}_qc_metrics"
        else ""

    String duplicate_metrics_command = if duplicate_metrics then 
        "--out-duplicate-metrics ${prefix}.duplicate-metrics.txt"
        else ""

    command <<<
        set -e

        # Make sure the reference and index files are in the task's working directory
        ln -s ~{ref.fasta} "$(basename ~{ref.fasta})"
        ln -s ~{ref.fasta_fai} "$(basename ~{ref.fasta_fai})"
        for bwa_file in ~{sep(" ", ref.bwa_index)}; do
            ln -s "$bwa_file" "$(basename "$bwa_file")"
        done

        pbrun \
            fq2bam \
            --ref "$(basename ~{ref.fasta})" \
            ~{in_fq_command} \
            --out-bam ~{prefix}.~{extension_bam} \
            ~{known_sites_command} \
            ~{known_sites_output_cmd} \
            ~{interval_file_command} \
            ~{qc_metrics_command} \
            ~{duplicate_metrics_command} \
            --num-gpus ~{num_gpus} \
            --monitor-usage \
            --preserve-file-symlinks \
            ~{sep(" ", select_first([args, []]))}
        >>>

    output {
        File bam = "${prefix}.${extension_bam}"
        File bai = "${prefix}.${extension_bam}.${extension_bam_index}"
        File? bqsr_table = if defined(known_sites) then "${prefix}.table" else None
        Directory? qc_metrics_path = if qc_metrics then "${prefix}_qc_metrics" else None
        File? duplicate_metrics_path = if duplicate_metrics then "${prefix}.duplicate-metrics.txt" else None
    }

    requirements {
        docker: container
        cpu: num_cpus
        memory: "~{memory} GB"
        gpu: true
    }

    hints {
        gpu: num_gpus
    }

    meta {
        author: "Gary Burnett (gburnett@nvidia.com)"
        description: "Converts FASTQ files to BAM/CRAM format using NVIDIA Parabricks fq2bam"
        outputs: {
            bam: "Aligned BAM/CRAM file",
            bai: "Index file for the BAM/CRAM",
            bqsr_table: "Optional BQSR table if known sites are provided",
            qc_metrics_path: "Optional QC metrics directory if specified in args",
            duplicate_metrics_path: "Optional duplicate metrics file if specified in args"
        }
    }

    parameter_meta {
        reads: {description: "Array of FASTQ files to align", category: "required"}
        ref: {description: "Struct containing Reference files (fasta, fasta.fai, bwa_index)", category: "required"}
        interval_file: {description: "Optional interval file for targeted regions (can be used multiple times)", category: "optional"}
        known_sites: {description: "Optional array of known variant sites for BQSR (can be used multiple times)", category: "optional"}
        output_fmt: {description: "Output format: 'bam' or 'cram'", category: "required"}
        single_ended: {description: "Whether reads are single-ended", category: "required"}
        qc_metrics: {description: "Whether to generate QC metrics", category: "required"}
        duplicate_metrics: {description: "Whether to generate duplicate metrics", category: "required"}
        prefix: {description: "Prefix for output files", category: "required"}
        args: {description: "Optional additional arguments for pbrun", category: "optional"}
        memory: {description: "Memory in GB", category: "required"}
        num_gpus: {description: "Number of GPUs to use", category: "required"}
        num_cpus: {description: "Number of CPU threads", category: "required"}
        container: {description: "Container image URI", category: "required"}
    }
}
