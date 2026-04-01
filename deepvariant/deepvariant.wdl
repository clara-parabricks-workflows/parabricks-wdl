version 1.2

import "../shared/ref_struct.wdl" as ref_struct

task deepvariant {

    input {
        File bam
        ReferenceFiles ref
        Array[File]? interval_file
        File? pb_model_file
        File? proposed_variants
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

    String pb_model_file_command = if defined(pb_model_file) then
        "--pb-model-file ${pb_model_file}"
        else ""

    String proposed_variants_command = if defined(proposed_variants) then
        "--proposed-variants ${proposed_variants}"
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
            deepvariant \
            --ref "$(basename ~{ref.fasta})" \
            --in-bam ~{bam} \
            --out-variants "~{prefix}.vcf" \
            ~{interval_file_command} \
            ~{pb_model_file_command} \
            ~{proposed_variants_command} \
            --num-gpus ~{num_gpus} \
            --preserve-file-symlinks \
            ~{sep(" ", select_first([args, []]))}
    >>>

    output {
        File vcf = "${prefix}.vcf"
        File? gvcf = "${prefix}.g.vcf.gz"
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
        description: "The NVIDIA Parabricks GPU accelerated version of DeepVariant"
        outputs: {
            vcf: "Output VCF file containing called variants",
            gvcf: "Optional output GVCF file containing variant and non-variant sites (only generated if --emit-ref-confidence is used)"
        }
    }

    parameter_meta {
        # inputs
        bam: {description: "Input BAM file to call variants on", category: "required"}
        ref: {description: "Reference genome files (FASTA, index, and BWA index)", category: "required"}
        interval_file: {description: "Optional interval file for targeted regions (can be used multiple times)", category: "optional"}
        pb_model_file: {description: "Optional custom Parabricks DeepVariant model file", category: "optional"}
        proposed_variants: {description: "Optional file of proposed variants", category: "optional"}
        prefix: {description: "Prefix for output files", category: "required"}
        args: {description: "Optional additional arguments for pbrun", category: "optional"}
        memory: {description: "Memory in GB", category: "required"}
        num_gpus: {description: "Number of GPUs to use", category: "required"}
        num_cpus: {description: "Number of CPU threads", category: "required"}
        container: {description: "Container image URI", category: "required"}
    }

}
