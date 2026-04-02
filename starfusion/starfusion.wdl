version 1.2

task starfusion {
    input {
        File chimeric_junction
        Directory genome_lib_dir
        String prefix
        Array[String]? args
        Int memory
        Int num_gpus
        Int num_cpus
        String container
    }

    command <<<
        set -e

        pbrun \
            starfusion \
            --chimeric-junction "~{chimeric_junction}" \
            --genome-lib-dir "~{genome_lib_dir}" \
            --output-dir "~{prefix}" \
            ~{sep(" ", select_first([args, []]))}

        # Dereference symlinks created by STAR-Fusion so sprocket's sandbox
        # does not reject links pointing outside the work directory.
        find "~{prefix}" -type l | while read link; do
            cp --dereference "$link" "$link.deref" && mv "$link.deref" "$link"
        done
    >>>

    output {
        Directory out_dir = "${prefix}"
    }

    requirements {
        docker: container
        cpu: num_cpus
        memory: "~{memory} GB"
        gpu: true
    }

    hints { 
        gpu: num_gpus 
    }

    meta { 
        author: "Gary Burnett (gburnett@nvidia.com)" 
        description: "NVIDIA Parabricks GPU accelerated StarFusion for fusion detection"
        outputs: {
            out_dir: "Directory containing the output files from StarFusion"
        }
    }

    parameter_meta {
        chimeric_junction: {description: "Chimeric junction file from STAR alignment", category: "required"}
        genome_lib_dir: {description: "STAR-Fusion genome library directory", category: "required"}
        prefix: {description: "Prefix for output files", category: "required"}
        args: {description: "Optional additional arguments for pbrun", category: "optional"}
        memory: {description: "Memory in GB", category: "required"}
        num_gpus: {description: "Number of GPUs to use", category: "required"}
        num_cpus: {description: "Number of CPU threads", category: "required"}
        container: {description: "Container image URI", category: "required"}
    }

}
