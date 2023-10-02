version 1.0

import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/util/attributes.wdl" as attributes

task indexBAM {
    input {
        File inputBAM
        String dockerImage = "erictdawson/samtools"

        RuntimeAttributes attributes = {
            "diskGB": 0,
            "nThreads": 4,
            "gbRAM": 11,
            "hpcQueue": "norm",
            "runtimeMinutes": 600,
            "maxPreemptAttempts": 3
        }

    }
    Int auto_diskGB = if attributes.diskGB == 0 then ceil(size(inputBAM, "GB") * 1.3) + 80 else attributes.diskGB

    String outbase = basename(inputBAM)
    command {
        samtools index ~{"-@ " + attributes.nThreads} ~{inputBAM} ~{outbase}.bai
    }
    output {
        File outputBAI = "~{outbase}.bai"
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