version 1.2

import "../shared/ref_struct.wdl" as ref_struct

task mutectcaller {
    input {
        ReferenceFiles ref
        File tumor_bam
        String tumor_name
        File? tumor_recal
        File? normal_bam
        String? normal_name
        File? normal_recal
        Array[File]? interval_file
        File? pon
        File? mutect_germline_resource   
        File? mutect_f1r2_tar_gz  
        File? mutect_alleles   
        String prefix
        Array[String]? args
        Int memory
        Int num_gpus
        Int num_cpus
        String container
    }

    String tumor_recal_command = if defined(tumor_recal) then
        "--in-tumor-recal ${tumor_recal}"
        else ""

    String normal_bam_command = if defined(normal_bam) then
        "--in-normal-bam ${normal_bam}"
        else ""

    String normal_name_command = if defined(normal_name) then
        "--normal-name ${normal_name}"
        else ""

    String normal_recal_command = if defined(normal_recal) then 
        "--in-normal-recal ${normal_recal}"
        else ""

    String interval_file_command = if defined(interval_file) then
        sep(" ", prefix("--interval-file ", select_first([interval_file, []])))
        else ""

    String mutect_germline_resource_command = if defined(mutect_germline_resource) then
        "--mutect-germline-resource ${mutect_germline_resource}"
        else ""

    String mutect_f1r2_tar_gz_command = if defined(mutect_f1r2_tar_gz) then
        "--mutect-f1r2-tar-gz ${mutect_f1r2_tar_gz}"
        else ""

    String mutect_alleles_command = if defined(mutect_alleles) then
        "--mutect-alleles ${mutect_alleles}"    
        else ""

    String pon_command = if defined(pon) then
        "--pon ${pon}"
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
            mutectcaller \
            --ref "$(basename ~{ref.fasta})" \
            --in-tumor-bam ~{tumor_bam} \
            --tumor-name ~{tumor_name} \
            ~{tumor_recal_command} \
            ~{normal_bam_command} \
            ~{normal_name_command} \
            ~{normal_recal_command} \
            ~{interval_file_command} \
            ~{mutect_germline_resource_command} \
            ~{mutect_f1r2_tar_gz_command} \
            ~{mutect_alleles_command} \
            ~{pon_command} \
            --out-vcf "~{prefix}.vcf" \
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
        memory: memory
        gpu: true
    }

    hints { 
        gpu: num_gpus 
    }

    meta { 
        author: "Gary Burnett (gburnett@nvidia.com)" 
        description: "NVIDIA Parabricks GPU accelerated MutectCaller"
        outputs: {
            vcf: "Output VCF file containing detected mutations"
        }
    }
    
    parameter_meta {
        ref: {description: "Reference genome files (FASTA, index, and BWA index)", category: "required"}
        tumor_bam: {description: "Input tumor BAM file", category: "required"}
        tumor_name: {description: "Name of the tumor sample", category: "required"}
        tumor_recal: {description: "Optional tumor BQSR recalibration table", category: "optional"}
        normal_bam: {description: "Optional normal BAM file", category: "optional"}
        normal_name: {description: "Optional name of the normal sample", category: "optional"}
        normal_recal: {description: "Optional normal BQSR recalibration table", category: "optional"}
        interval_file: {description: "Optional interval file for targeted regions (can be used multiple times)", category: "optional"}
        pon: {description: "Optional panel of normals VCF file", category: "optional"}
        mutect_germline_resource: {description: "Optional Mutect2 germline resource VCF file", category: "optional"}
        mutect_f1r2_tar_gz: {description: "Optional Mutect2 F1R2 tar.gz file for orientation bias modeling", category: "optional"}
        mutect_alleles: {description: "Optional alleles VCF file to force-genotype", category: "optional"}
        prefix: {description: "Prefix for output files", category: "required"}
        args: {description: "Optional additional arguments for pbrun", category: "optional"}
        memory: {description: "Memory in GB", category: "required"}
        num_gpus: {description: "Number of GPUs to use", category: "required"}
        num_cpus: {description: "Number of CPU threads", category: "required"}
        container: {description: "Container image URI", category: "required"}
    }
}
