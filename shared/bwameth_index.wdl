version 1.2

task bwameth_index {
    input {
        File fasta
        Array[String]? args = []
        Int memory = 8
        Int num_cpus = 4
        String container = "josousa/bwa-meth:0.2.7"
    }

    # Use a local symlink to avoid writing into the read-only input mount
    String local = basename(fasta)

    command <<<
        set -e

        # Create or update a symlink in the task working dir and index that
        ln -sf "~{fasta}" "~{local}"

        bwameth.py index "~{local}" ~{sep(" ", select_first([args, []]))}
    >>>

    output {
        File fasta_c2t = "${local}.bwameth.c2t"
        File amb = "${local}.bwameth.c2t.amb"
        File ann = "${local}.bwameth.c2t.ann"
        File bwt = "${local}.bwameth.c2t.bwt"
        File pac = "${local}.bwameth.c2t.pac"
        File sa  = "${local}.bwameth.c2t.sa"
        Array[File] index_files = [fasta_c2t, amb, ann, bwt, pac, sa]
    }

    requirements {
        docker: container
        cpu: num_cpus
        memory: memory
    }

    meta { 
        author: "Gary Burnett (gburnett@nvidia.com)"
        description: "Creates index files for use with bwa-meth or BWA" 
        outputs: {
            fasta_c2t: "BWA-meth indexed FASTA file",
            amb: "BWA-meth .amb index file",
            ann: "BWA-meth .ann index file",
            bwt: "BWA-meth .bwt index file",
            pac: "BWA-meth .pac index file",
            sa: "BWA-meth .sa index file",
            index_files: "Array of BWA-meth index files"
        }
    }

    parameter_meta {
        fasta: "Reference FASTA file to index"
        args: "Optional additional arguments for indexing tool"
        memory: "Memory in GB"
        num_cpus: "Number of CPU threads"
        container: "Container image URI"
    }
}
