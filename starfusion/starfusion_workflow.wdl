version 1.2

import "starfusion.wdl" as starfusion
import "../rnafq2bam/rnafq2bam.wdl" as rnafq2bam
import "../shared/bwa_index.wdl" as bwa_index
import "../shared/samtools_faidx.wdl" as samtools_faidx
import "../shared/starfusion_build.wdl" as starfusion_build
import "../shared/star_genomegenerate.wdl" as star_genomegenerate

workflow starfusion_workflow {
    input {
        Array[File] reads
        File fasta
        File gtf
        String output_fmt
        Boolean single_ended
        Boolean qc_metrics
        Boolean duplicate_metrics
        String prefix
        File fusion_annot_lib
        String pfam_db
        String dfam_db
        File annot_filter_url
        Int memory
        Int num_gpus
        Int num_cpus
        String container
    }

    call star_genomegenerate.star_genomegenerate {
        fasta = fasta, 
        gtf = gtf,
        genome_lib_dir_name = "STAR"
    }

    call samtools_faidx.samtools_faidx {
        fasta = fasta
    }

    call bwa_index.bwa_index {
        fasta = fasta
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
        args = ["--read-files-command zcat", "--out-chim-type Junctions", "--min-chim-segment 15"],
        memory = memory,
        num_gpus = num_gpus,
        num_cpus = num_cpus,
        container = container
    }

    call starfusion_build.starfusion_build {
        fasta = fasta,
        gtf = gtf,
        genome_lib_dir_name = "STAR-Fusion",
        fusion_annot_lib = fusion_annot_lib,
        pfam_db = pfam_db,
        dfam_db = dfam_db,
        annot_filter_url = annot_filter_url,
        memory = memory,
        num_cpus = num_cpus
    }

    call starfusion.starfusion {
        chimeric_junction = select_first([rnafq2bam.junction]),
        genome_lib_dir = starfusion_build.genome_lib_dir,
        prefix = prefix,
        memory = memory,
        num_gpus = num_gpus,
        num_cpus = num_cpus,
        container = container
    }

    output {
        Directory out_dir = starfusion.out_dir
    }

    meta {
        author: "Gary Burnett (gburnett@nvidia.com)"
        description: "NVIDIA Parabricks GPU accelerated STAR-Fusion workflow"
        outputs: {
            out_dir: "Directory containing STAR-Fusion output files"
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
        fusion_annot_lib: {description: "STAR-Fusion fusion annotation library file", category: "required"}
        pfam_db: {description: "Pfam database identifier for fusion annotation", category: "required"}
        dfam_db: {description: "Dfam database identifier for repeat masking", category: "required"}
        annot_filter_url: {description: "URL for the annotation filter file", category: "required"}
        memory: {description: "Memory in GB", category: "required"}
        num_gpus: {description: "Number of GPUs to use", category: "required"}
        num_cpus: {description: "Number of CPU threads", category: "required"}
        container: {description: "Container image URI", category: "required"}
    }
}
