version 1.0
# Copyright 2023 NVIDIA CORPORATION & AFFILIATES

task deepvariant {
    input {
        File inputBAM
        File inputBAI
        File inputReference
        Boolean gvcfMode = false

        Int nThreads = 32
        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.1.1-1"
        Int diskGB = 0
        Int gbRAM = 62
        String hpcQueue = "norm"
        Int runtimeMinutes = 240
        Int maxPreemptAttempts = 3  
    }

    String outbase = basename(inputBAM, ".bam")
    String outVCF = outbase + ".deepvariant" + (if gvcfMode then '.g' else '') + ".vcf"
    Int auto_diskGB = if diskGB == 0 then ceil(size(inputBAM, "GB") * 3.2) + ceil(size(inputReference, "GB") * 3) + 80 else diskGB

    command {
        time pbrun deepvariant \
        ~{if gvcfMode then "--gvcf " else ""} \
        --ref ${inputReference} \
        --in-bam ${inputBAM} \
        --out-variants ~{outVCF} 
    }

    output {
        File deepvariantVCF = "~{outVCF}"
    }

    runtime {
        docker : "~{pbDocker}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : nThreads
        memory : "~{gbRAM} GB"
        hpcMemory : gbRAM
        hpcQueue : "~{hpcQueue}"
        hpcRuntimeMinutes : runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : maxPreemptAttempts
    }
}