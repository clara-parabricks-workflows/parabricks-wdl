version 1.2

import "mutectcaller.wdl" as mutectcaller
import "../shared/bwa_index.wdl" as bwa_index
import "../shared/samtools_faidx.wdl" as samtools_faidx

workflow mutectcaller_workflow {
    input {
        File fasta
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

    call samtools_faidx.samtools_faidx {
        fasta = fasta
    }

    call bwa_index.bwa_index {
        fasta = fasta
    }

    call mutectcaller.mutectcaller {
        ref = ReferenceFiles { 
            fasta: fasta, 
            fasta_fai: samtools_faidx.fai,
            bwa_index: bwa_index.index_files 
        },
        tumor_bam = tumor_bam,
        tumor_name = tumor_name,
        tumor_recal = tumor_recal,
        normal_bam = normal_bam,
        normal_name = normal_name,
        normal_recal = normal_recal,
        interval_file = interval_file,
        pon = pon,
        mutect_germline_resource = mutect_germline_resource,
        mutect_f1r2_tar_gz = mutect_f1r2_tar_gz,
        mutect_alleles = mutect_alleles,
        prefix = prefix,
        args = args,
        memory = memory,
        num_gpus = num_gpus,
        num_cpus = num_cpus,
        container = container
    }

    output { 
        File vcf = mutectcaller.vcf 
    }
    
    meta { 
        author: "Gary Burnett (gburnett@nvidia.com)" 
        description: "Mutectcaller test workflow"
        outputs: {
            vcf: "VCF output from Mutectcaller"
        }
    }

    parameter_meta {
        fasta: {description: "Reference genome FASTA file", category: "required"}
        tumor_bam: {description: "Tumor BAM file", category: "required"}
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
