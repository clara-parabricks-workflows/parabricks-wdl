version 1.2

import "../shared/ref_struct.wdl" as ref_struct

task haplotypecaller {

    input {
        File bam
        ReferenceFiles ref
        Array[File]? interval_file
        Array[File]? known_sites
        String prefix
        Array[String]? args
        Int memory
        Int num_gpus
        Int num_cpus
        String container
    }

    String interval_file_command = if defined(interval_file) then
        sep(" ", prefix("--interval-file ", select_first([interval_file, []])))
        else ""

    String known_sites_command = if defined(known_sites) then
        sep(" ", prefix("--knownSites ", select_first([known_sites, []])))
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
            haplotypecaller \
            --ref "$(basename ~{ref.fasta})" \
            --in-bam ~{bam} \
            --out-variants "~{prefix}.vcf" \
            ~{interval_file_command} \
            ~{known_sites_command} \
            --num-gpus ~{num_gpus} \
            --preserve-file-symlinks \
            ~{sep(" ", select_first([args, []]))}
    >>>

    output {
        File vcf = "${prefix}.vcf"
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
        description: "NVIDIA Parabricks GPU accelerated HaplotypeCaller"
        outputs: {
            vcf: "VCF file produced by HaplotypeCaller"
        }
    }

    parameter_meta {
        bam: {description: "Input BAM file to call variants on", category: "required"}
        ref: {description: "Reference genome files (FASTA, index, and BWA index)", category: "required"}
        interval_file: {description: "Optional interval file for targeted regions (can be used multiple times)", category: "optional"}
        known_sites: {description: "Optional array of known variant sites for BQSR (can be used multiple times)", category: "optional"}
        prefix: {description: "Prefix for output files", category: "required"}
        args: {description: "Optional additional arguments for pbrun", category: "optional"}
        memory: {description: "Memory in GB", category: "required"}
        num_gpus: {description: "Number of GPUs to use", category: "required"}
        num_cpus: {description: "Number of CPU threads", category: "required"}
        container: {description: "Container image URI", category: "required"}
    }

}
