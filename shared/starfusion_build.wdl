version 1.2

task starfusion_build {
    input {
        File fasta
        File gtf
        String genome_lib_dir_name
        File fusion_annot_lib
        String pfam_db
        String dfam_db
        File annot_filter_url
        Array[String]? args
        Int memory
        Int num_cpus
        String container = "community.wave.seqera.io/library/dfam_hmmer_minimap2_star-fusion:e285bb3eb373b9a7"
    }

    command <<<
            prep_genome_lib.pl \
            --genome_fa "~{fasta}" \
            --gtf "~{gtf}" \
            --dfam_db "~{dfam_db}" \
            --pfam_db "~{pfam_db}" \
            --fusion_annot_lib "~{fusion_annot_lib}" \
            --annot_filter_rule "~{annot_filter_url}" \
            --CPU ~{num_cpus} \
            --output_dir ~{genome_lib_dir_name} \
            ~{sep(" ", select_first([args, []]))}
    >>>

    output {
        Directory genome_lib_dir = "${genome_lib_dir_name}"
    }

    requirements {
        docker: container
        cpu: num_cpus
        memory: memory
        gpu: true
    }
}