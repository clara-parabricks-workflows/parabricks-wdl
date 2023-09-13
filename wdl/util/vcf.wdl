version 1.0

import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/util/attributes.wdl" as attributes

task compressAndIndexVCF {
    input {
        File inputVCF
        String dockerImage = "erictdawson/bcftools"

        RuntimeAttributes runtimeAttributes = {
            "diskGB": 0,
            "nThreads": 4,
            "gbRAM": 11,
            "hpcQueue": "norm",
            "runtimeMinutes": 600,
            "gpuDriverVersion": "535.104.05",
            "maxPreemptAttempts": 3
        }

    }
    Int auto_diskGB = if runtimeAttributes.diskGB == 0 then ceil(size(inputVCF, "GB") * 1.8) + 80 else runtimeAttributes.diskGB

    String outbase = basename(inputVCF, ".vcf")
    command {
        bgzip -d ~{"-@ " + runtime_attributes.nThreads} ~{inputVCF} > ~{outbase}.vcf.gz && \
        tabix ~{outbase}.vcf.gz
    }
    output {
        File outputVCFGZ = "~{outbase}.vcf.gz"
        File outputTBI = "~{outbase}.vcf.gz.tbi"
    }
    runtime {
        docker : "~{dockerImage}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : runtimeAttributes.nThreads
        memory : "~{runtimeAttributes.gbRAM} GB"
        hpcMemory : runtimeAttributes.gbRAM
        hpcQueue : "~{runtimeAttributes.hpcQueue}"
        hpcRuntimeMinutes : runtimeAttributes.runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : runtimeAttributes.maxPreemptAttempts
    }
}