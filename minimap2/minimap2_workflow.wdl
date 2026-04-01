version 1.2

import "minimap2.wdl" as minimap2  
import "../shared/bwa_index.wdl" as bwa_index
import "../shared/samtools_faidx.wdl" as samtools_faidx

workflow minimap2_workflow {
    input {
        File? reads_fq
        File? reads_bam
        File? index 
        File fasta
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

    call samtools_faidx.samtools_faidx {
        fasta = fasta
    }

    call bwa_index.bwa_index {
        fasta = fasta
    }

    call minimap2.minimap2 {
        reads_fq = reads_fq,
        reads_bam = reads_bam,
        index = index, 
        ref = ReferenceFiles { 
            fasta: fasta, 
            fasta_fai: samtools_faidx.fai,
            bwa_index: bwa_index.index_files 
        },
        interval_file = interval_file,
        known_sites = known_sites,
        output_fmt = output_fmt,
        prefix = prefix,
        args = args,
        memory = memory,
        num_gpus = num_gpus,
        num_cpus = num_cpus,
        container = container
    }

    output {
        File bam = minimap2.bam
        File bai = minimap2.bai
    }
    
    meta { 
        author: "Gary Burnett (gburnett@nvidia.com)" 
        description: "Test workflow for minimap2 alignment"
        outputs: {
            bam: "Aligned reads in BAM or CRAM format",
            bai: "Index file for the aligned BAM or CRAM"
        }
    }

    parameter_meta {
        reads_fq: {description: "Input FASTQ file", category: "optional"}
        reads_bam: {description: "Input BAM file", category: "optional"}
        index: {description: "Pre-built minimap2 index", category: "optional"}
        fasta: {description: "Reference genome FASTA file", category: "required"}
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
