version 1.2

import "fq2bammeth.wdl" as fq2bammeth
import "../shared/bwameth_index.wdl" as bwameth_index

workflow fq2bammeth_workflow {
    input {
        Array[File] reads
        File fasta
        Array[File]? interval_file
        Array[File]? known_sites
        String output_fmt
        Boolean single_ended
        String prefix
        Array[String]? args
        Int memory
        Int num_gpus
        Int num_cpus
        String container
    }

    call bwameth_index.bwameth_index {
        fasta = fasta
    }

    call fq2bammeth.fq2bammeth {
        reads = reads,
        ref = ReferenceFiles { 
            fasta: fasta, 
            bwa_index: bwameth_index.index_files 
        },
        interval_file = interval_file,
        known_sites = known_sites,
        output_fmt = output_fmt,
        single_ended = single_ended,
        prefix = prefix,
        args = args,
        memory = memory,
        num_gpus = num_gpus,
        num_cpus = num_cpus,
        container = container
    }

    output {
        File bam = fq2bammeth.bam
        File bai = fq2bammeth.bai
        File? meth_metrics = fq2bammeth.meth_metrics
    }

    meta { 
        author: "Gary Burnett (gburnett@nvidia.com)" 
        description: "Converts FASTQ files to BAM/CRAM format with methylation metrics using NVIDIA Parabricks fq2bammeth"
        outputs: {
            bam: "Aligned methylation-aware BAM/CRAM file", 
            bai: "BAM/CRAM index file",
            meth_metrics: "Methylation metrics file (if requested)"
        }
    }

    parameter_meta {
        reads: "Array of FASTQ files to align"
        fasta: "Reference genome FASTA file"
        interval_file: "Optional interval files to restrict alignment"
        known_sites: "Optional known sites files for methylation calling"
        output_fmt: "Output format: 'bam' or 'cram'"
        single_ended: "Boolean indicating if the reads are single-ended"
        prefix: "Prefix for output files"
        args: "Additional command-line arguments for fq2bammeth"
        memory: "Amount of memory to allocate (e.g., '16 GB')"
        num_gpus: "Number of GPUs to use"
        num_cpus: "Number of CPU cores to allocate"
        container: "Docker container image to use"
    }
}
