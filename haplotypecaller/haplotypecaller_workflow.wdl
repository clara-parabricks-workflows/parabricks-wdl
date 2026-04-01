version 1.2

import "haplotypecaller.wdl" as haplotypecaller
import "../shared/bwa_index.wdl" as bwa_index
import "../shared/samtools_faidx.wdl" as samtools_faidx

workflow haplotypecaller_workflow {

    input {
        File bam
        File fasta
        Array[File]? interval_file
        Array[File]? known_sites
        Array[String]? args
        String prefix
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

    call haplotypecaller.haplotypecaller {
        bam = bam,
        ref = ReferenceFiles { 
            fasta: fasta, 
            fasta_fai: samtools_faidx.fai,
            bwa_index: bwa_index.index_files 
        },
        interval_file = interval_file,
        known_sites = known_sites,
        prefix = prefix,
        args = args,
        memory = memory,
        num_gpus = num_gpus,
        num_cpus = num_cpus,
        container = container
    }

    output {
        File vcf = haplotypecaller.vcf
    }

    meta {
        author: "Gary Burnett (gburnett@nvidia.com)"
        description: "NVIDIA Parabricks GPU Accelerated HaplotypeCaller"
        outputs: {
            vcf: "VCF file containing called variants"
        }
    }

    parameter_meta {
        bam: {description: "Input BAM file to call variants on", category: "required"}
        fasta: {description: "Reference genome FASTA file", category: "required"}
        interval_file: {description: "Optional interval file for targeted regions (can be used multiple times)", category: "optional"}
        known_sites: {description: "Optional array of known variant sites for BQSR (can be used multiple times)", category: "optional"}
        args: {description: "Optional additional arguments for pbrun", category: "optional"}
        prefix: {description: "Prefix for output files", category: "required"}
        memory: {description: "Memory in GB", category: "required"}
        num_gpus: {description: "Number of GPUs to use", category: "required"}
        num_cpus: {description: "Number of CPU threads", category: "required"}
        container: {description: "Container image URI", category: "required"}
    }

}
