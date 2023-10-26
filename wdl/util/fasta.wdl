version 1.0

import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/util/attributes.wdl" as attributes


## Merge a collection of BAM files into a single BAM file.
task getContigsFromFAI {
    input {
        File inputRefTarball
        String dockerImage = "erictdawson/samtools"
        
        RuntimeAttributes attributes = {
            "diskGB": 0,
            "nThreads": 1,
            "gbRAM": 5,
            "hpcQueue": "norm",
            "runtimeMinutes": 600,
            "maxPreemptAttempts": 3
        }
    }
    Int auto_diskGB = if attributes.diskGB == 0 then ceil(size(inputRefTarball, "GB") * 3.0) + 30 else attributes.diskGB

    String ref = basename(inputRefTarball, ".tar")

    command {
        tar xvf ~{inputRefTarball} -C `pwd` && \
        cat ~{ref}.fai | cut -f 1
    }
    output {
        Array[String] scatter_contigs = read_lines(stdout())
    }
    runtime {
        docker : "~{dockerImage}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : attributes.nThreads
        memory : "~{attributes.gbRAM} GB"
        hpcMemory : attributes.gbRAM
        hpcQueue : "~{attributes.hpcQueue}"
        hpcRuntimeMinutes : attributes.runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : attributes.maxPreemptAttempts
    }
}