version 1.2

import "fq2bam.wdl" as fq2bam
import "../shared/bwa_index.wdl" as bwa_index
import "../shared/samtools_faidx.wdl" as samtools_faidx

workflow fq2bam_workflow {
    input {
        Array[File] reads
        File fasta
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

    call samtools_faidx.samtools_faidx {
        fasta = fasta
    }

    call bwa_index.bwa_index {
        fasta = fasta
    }

    call fq2bam.fq2bam {
        reads = reads,
        ref = ReferenceFiles { 
            fasta: fasta, 
            fasta_fai: samtools_faidx.fai,
            bwa_index: bwa_index.index_files 
        },
        interval_file = interval_file,
        known_sites = known_sites, 
        output_fmt = output_fmt, 
        single_ended = single_ended, 
        qc_metrics = qc_metrics,
        duplicate_metrics = duplicate_metrics,
        prefix = prefix,
        args = args, 
        memory = memory, 
        num_gpus = num_gpus, 
        num_cpus = num_cpus, 
        container = container
    }

    output {
        File bam = fq2bam.bam
        File bai = fq2bam.bai
        File? bqsr_table = fq2bam.bqsr_table
        Directory? qc_metrics_path = fq2bam.qc_metrics_path
        File? duplicate_metrics_path = fq2bam.duplicate_metrics_path
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
        reads: "Sample sheet of FASTQ files to align"
        fasta: "Reference genome FASTA file"
        interval_file: "Optional interval file for targeted regions (can be used multiple times)"
        known_sites: "Optional array of known variant sites for BQSR (can be used multiple times)"
        output_fmt: "Output format: 'bam' or 'cram'"
        single_ended: "Whether reads are single-ended"
        qc_metrics: "Boolean indicating if QC metrics should be generated"
        duplicate_metrics: "Boolean indicating if duplicate metrics should be generated"
        prefix: "Prefix for output files"
        args: "Optional additional arguments for pbrun"
        memory: "Memory requirement (in GB) for the task"
        num_gpus: "Number of GPUs to use"
        num_cpus: "Number of CPU threads"
        container: "Container image URI"
    }
}
