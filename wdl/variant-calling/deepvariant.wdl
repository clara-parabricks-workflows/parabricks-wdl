version 1.0
# Copyright 2023 NVIDIA CORPORATION & AFFILIATES
import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/util/attributes.wdl"

task deepvariant {
    input {
        File inputBAM
        File inputBAI
        File inputRefTarball
        String? mode
        File? modelFile
        String? deepvariantFlags
        Boolean gvcfMode = false

        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.1.1-1"
        String pbPATH = "pbrun"
        File? pbLicenseBin
        RuntimeAttributes runtime_attributes
        GPUAttributes gpu_attributes

    }

    String outbase = basename(inputBAM, ".bam")
    String outVCF = outbase + ".deepvariant" + (if gvcfMode then '.g' else '') + ".vcf"
    Int auto_diskGB = if diskGB == 0 then ceil(size(inputBAM, "GB") * 3.2) + ceil(size(inputReference, "GB") * 3) + 80 else diskGB

    command {
        time pbrun deepvariant \
        ~{"--mode " + mode} \
        ~{"--pb-model-file " + modelFile} \
        ~{"" + deepvariantFlags} \
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