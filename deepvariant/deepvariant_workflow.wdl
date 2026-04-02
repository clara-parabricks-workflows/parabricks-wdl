version 1.2

import "deepvariant.wdl" as deepvariant
import "../shared/bwa_index.wdl" as bwa_index
import "../shared/samtools_faidx.wdl" as samtools_faidx

workflow deepvariant_workflow {

    input {
        File bam
        File fasta
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

    call samtools_faidx.samtools_faidx {
        fasta = fasta
    }

    call bwa_index.bwa_index {
        fasta = fasta
    }

    call deepvariant.deepvariant {
        bam = bam,
        ref = ReferenceFiles { 
            fasta: fasta, 
            fasta_fai: samtools_faidx.fai,
            bwa_index: bwa_index.index_files 
        },
        interval_file = interval_file,
        pb_model_file = pb_model_file,
        proposed_variants = proposed_variants,
        prefix = prefix,
        args = args, 
        memory = memory, 
        num_gpus = num_gpus, 
        num_cpus = num_cpus, 
        container = container
    }

    output {
        File vcf = deepvariant.vcf
        File? gvcf = deepvariant.gvcf
    }

    meta {
        author: "Gary Burnett (gburnett@nvidia.com)"
        description: "NVIDIA Parabricks GPU Accelerated DeepVariant"
        outputs: {
            vcf: "VCF file created with DeepVariant",
            gvcf: "bgzipped gVCF created with DeepVariant"
        }
    }

    parameter_meta {
        bam: "The input BAM file"
        fasta: "Reference genome FASTA file"
        interval_file: "Optional interval file for targeted regions (can be used multiple times)"
        pb_model_file: "Optional Parabricks model file for DeepVariant"
        proposed_variants: "Optional proposed variants file (*.vcf.gz) for the make examples stage"
        prefix: "Prefix for output files"
        args: "Optional additional arguments for pbrun"
        memory: "Memory in GB"
        num_gpus: "Number of GPUs to use"
        num_cpus: "Number of CPU threads"
        container: "Container image URI"
    }

}
