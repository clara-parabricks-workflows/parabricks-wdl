version 1.2

import "../shared/ref_struct.wdl" as ref_struct

task rnafq2bam {
    input {
        Array[File] reads
        ReferenceFiles ref
        Directory genome_lib_dir
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

    String extension_bam = output_fmt
    String extension_bam_index = if output_fmt == "cram" then "crai" else "bai"

    String in_fq_command = if single_ended then 
        sep(" ", prefix("--in-se-fq ", reads))
        else "--in-fq ${sep(" ", reads)}"

    String qc_metrics_command = if qc_metrics then 
        "--out-qc-metrics-dir ${prefix}_qc_metrics"
        else ""

    String duplicate_metrics_command = if duplicate_metrics then 
        "--out-duplicate-metrics ${prefix}.duplicate-metrics.txt"
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
            rna_fq2bam \
            --ref "$(basename ~{ref.fasta})" \
            ~{in_fq_command} \
            --genome-lib-dir ~{genome_lib_dir} \
            ~{qc_metrics_command} \
            ~{duplicate_metrics_command} \
            --output-dir . \
            --out-bam "~{prefix}.~{extension_bam}" \
            --num-gpus ~{num_gpus} \
            --preserve-file-symlinks \
            ~{sep(" ", select_first([args, []]))}
    >>>

    output {
        File bam = "${prefix}.${extension_bam}"
        File bai = "${prefix}.${extension_bam}.${extension_bam_index}"
        Directory? qc_metrics_path = if qc_metrics then "${prefix}_qc_metrics" else None
        File? duplicate_metrics_path = if duplicate_metrics then "${prefix}.duplicate-metrics.txt" else None
        File? junction = "*.out.junction"
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
        description: "NVIDIA Parabricks GPU accelerated RNA FASTQ to BAM"
        outputs: {
            bam: "BAM file output",
            bai: "BAM index file output",
            qc_metrics_path: "Directory containing quality control metrics if enabled",
            duplicate_metrics_path: "File containing duplicate metrics if enabled",
            junction: "File containing junction information"
        }
    }

    parameter_meta {
        reads: "Input RNA FASTQ files"
        ref: "Reference files for the genome"
        genome_lib_dir: "Directory containing genome libraries"
        output_fmt: "Output file format (bam or cram)"
        single_ended: "Flag indicating if the input reads are single-ended"
        qc_metrics: "Flag indicating if quality control metrics should be generated"
        duplicate_metrics: "Flag indicating if duplicate metrics should be generated"
        prefix: "Prefix for the output files"
        args: "Additional arguments for the rnafq2bam command"
        memory: "Memory requirement for the task"
        num_gpus: "Number of GPUs required for the task"
        num_cpus: "Number of CPUs required for the task"
        container: "Docker container to use for the task"
    }
}
