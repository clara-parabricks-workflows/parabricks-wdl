version 1.2

task star_genomegenerate {
    input {
        File fasta
        File? gtf
        String genome_lib_dir_name
        Array[String]? args = []
        Int memory = 32
        Int num_cpus = 8
        String container = "community.wave.seqera.io/library/htslib_samtools_star_gawk:4de2f983041d42e6" 
    }

    command <<<
        set -e

        mkdir -p "~{genome_lib_dir_name}"
        STAR --runMode genomeGenerate \
             --genomeDir "~{genome_lib_dir_name}" \
             --genomeFastaFiles "~{fasta}" \
             --runThreadN ~{num_cpus} \
             "~{if defined(gtf) then "--sjdbGTFfile " + gtf else ""}" \
             "~{sep(" ", select_first([args, []]))}"

    >>>

    output {
        Directory genome_lib_dir = genome_lib_dir_name
    }

    requirements {
        docker: container
        cpu: num_cpus
        memory: memory
    }

    meta { 
        author: "Gary Burnett (gburnett@nvidia.com)" 
        description: "Build STAR genome index using baseline STAR" 
        outputs: {
            genome_lib_dir: "STAR genome index directory"
        }
    }

    parameter_meta {
        fasta: "Reference FASTA file to build STAR index"
        gtf: "Optional GTF file to incorporate splice junctions"
        genome_lib_dir_name: "Output STAR genome directory name"
        args: "Optional additional arguments for STAR"
        memory: "Memory in GB"
        num_cpus: "Number of CPU threads"
        container: "Container image URI"
    }
}
