version 1.2

import "rnafq2bam.wdl" as rnafq2bam
import "../shared/bwa_index.wdl" as bwa_index
import "../shared/samtools_faidx.wdl" as samtools_faidx
import "../shared/star_genomegenerate.wdl" as star_genomegenerate

workflow rnafq2bam_workflow {
    input {
        Array[File] reads
        File fasta
        File gtf
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

    call star_genomegenerate.star_genomegenerate {
        fasta = fasta,
        gtf = gtf,
        genome_lib_dir_name = "STAR"
    }

    call rnafq2bam.rnafq2bam {
        reads = reads,
        ref = ReferenceFiles { 
            fasta: fasta, 
            fasta_fai: samtools_faidx.fai,
            bwa_index: bwa_index.index_files 
        },
        genome_lib_dir = star_genomegenerate.genome_lib_dir,
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
        File bam = rnafq2bam.bam
        File bai = rnafq2bam.bai
        Directory? qc_metrics_path = rnafq2bam.qc_metrics_path
        File? duplicate_metrics_path = rnafq2bam.duplicate_metrics_path
        File? junction = rnafq2bam.junction
    }

    meta {
        author: "Gary Burnett (gburnett@nvidia.com)"
        description: "Converts FASTQ files to BAM/CRAM format using NVIDIA Parabricks fq2bam"
        outputs: {
            bam: "BAM/CRAM file",
            bai: "BAM/CRAM index file",
            qc_metrics_path: "Directory containing QC metrics (if qc_metrics is true)",
            duplicate_metrics_path: "File containing duplicate metrics (if duplicate_metrics is true)",
            junction: "File containing junction information (if output_fmt is 'cram')"
        }
    }

    parameter_meta {
        reads: {description: "Array of FASTQ files to align", category: "required"}
        fasta: {description: "Reference genome FASTA file", category: "required"}
        gtf: {description: "Reference GTF annotation file", category: "required"}
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
