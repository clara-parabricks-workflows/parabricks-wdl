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

        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.2.0-1"

        RuntimeAttributes runtime_attributes
        GPUAttributes gpu_attributes

    }


    String ref = basename(inputRefTarball, ".tar")
    String localTarball = basename(inputRefTarball)

    String outbase = basename(inputBAM, ".bam")
    String outVCF = outbase + ".deepvariant" + (if gvcfMode then '.g' else '') + ".vcf"

    Int auto_diskGB = if runtime_attributes.diskGB == 0 then ceil(size(inputBAM, "GB") * 3.2) + ceil(size(inputRefTarball, "GB") * 3) + 80 else runtime_attributes.diskGB

    command {
        mv ~{inputRefTarball} ~{localTarball} && \
        tar xvf ~{localTarball} && \
        time pbrun deepvariant \
        ~{"--mode " + mode} \
        ~{"--pb-model-file " + modelFile} \
        ~{"" + deepvariantFlags} \
        ~{if gvcfMode then "--gvcf " else ""} \
        --ref ${ref} \
        --in-bam ${inputBAM} \
        --out-variants ~{outVCF} 
    }

    output {
        File outputVCF = "~{outVCF}"
    }

    runtime {
        docker : "~{pbDocker}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : runtime_attributes.nThreads
        memory : "~{runtime_attributes.gbRAM} GB"
        hpcMemory : runtime_attributes.gbRAM
        hpcQueue : "~{runtime_attributes.hpcQueue}"
        hpcRuntimeMinutes : runtime_attributes.runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : runtime_attributes.maxPreemptAttempts
        gpuType : "~{gpu_attributes.gpuModel}"
        gpuCount : gpu_attributes.nGPU
        nvidiaDriverVersion : "~{gpu_attributes.gpuDriverVersion}"
    }
}