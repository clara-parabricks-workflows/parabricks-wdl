version 1.0
# Copyright 2023 NVIDIA CORPORATION & AFFILIATES

# import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/util/attributes.wdl" as attributes
import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/util/attributes.wdl" as attributes



task pbmm2 {
    input {
        File inputFASTQ
        File inputReference
        File? referenceIndex
        String sampleName
        String? preset
        String mm2Preset = "map-ont"
        Int nThreads = 32
        Int mapThreads = 28

        String pbmm2Docker = "erictdawson/pbmm2"
        RuntimeAttributes runtime_attributes
    }

    Int sort_threads = 4
    ## Put a ceiling on mm2_threads so as not to oversubscribe our VM
    ## mm2_threads = min(mapThreads, nThreads - sort_threads - 1)
    Int mm2_threads = if runtime_attributes.nThreads - sort_threads >= mapThreads then mapThreads else runtime_attributes.nThreads - sort_threads -1
    String outbase = basename(basename(basename(inputFASTQ, ".gz"), ".fq"), ".fastq")
    Int auto_diskGB = if runtime_attributes.diskGB == 0 then ceil(size(inputFASTQ, "GB") * 3.2) + ceil(size(inputReference, "GB") * 3) + 80 else runtime_attributes.diskGB

    command <<<
        time pbmm2 align \
            ~{inputReference} \
            ~{inputFASTQ} \
            ~{outbase}.bam \
            ~{"--preset " +  preset} \
            --sort \
            --rg '@RG\tID:~{sampleName}\tSM:~{sampleName}' \
            -j ~{mm2_threads} \
            -J ~{sort_threads} && \
            tabix ~{outbase}.bam
    >>>

    output {
        File outputBAM = "~{outbase}.bam"
        File outputBAI= "~{outbase}.bam.bai"
    }

    runtime {
        docker : "~{pbmm2Docker}"
        disks : "local-disk ~{runtime_attributes.auto_diskGB} SSD"
        cpu : runtime_attributes.nThreads
        memory : "~{runtime_attributes.gbRAM} GB"
        hpcMemory : runtime_attributes.gbRAM
        hpcQueue : "~{runtime_attributes.hpcQueue}"
        hpcRuntimeMinutes : runtime_attributes.runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : runtime_attributes.maxPreemptAttempts
    }
}

task minimap2 {
    input {
        File inputFASTQ
        File inputReference
        File? referenceIndex
        String sampleName
        String mm2Preset = "map-ont"
        Int nThreads = 32
        Int mapThreads = 28

        String minimapDocker = "erictdawson/minimap2"
        RuntimeAttributes runtime_attributes
    }

    Int sort_threads = 4
    ## Put a ceiling on mm2_threads so as not to oversubscribe our VM
    ## mm2_threads = min(mapThreads, nThreads - sort_threads - 1)
    Int mm2_threads = if nThreads - sort_threads >= mapThreads then mapThreads else nThreads - sort_threads -1
    String outbase = basename(basename(basename(inputFASTQ, ".gz"), ".fq"), ".fastq")
    Int auto_diskGB = if runtime_attributes.diskGB == 0 then ceil(size(inputFASTQ, "GB") * 3.2) + ceil(size(inputReference, "GB") * 3) + 80 else runtime_attributes.diskGB

    command <<<
        time minimap2 \
            -Y \
            -H \
            -y \
            --MD \
            -t ~{mm2_threads} \
            -R "@RG\tSM:~{sampleName}\tID:~{sampleName}" \
            -ax ~{mm2Preset} \
            ~{inputReference} \
            ~{inputFASTQ} | \
        samtools sort \
            -m 6G \
            -@ ~{sort_threads} - \
            > ~{outbase}.bam && \
            samtools index ~{outbase}.bam
    >>>

    output {
        File outputBAM = "~{outbase}.bam"
        File outputBAI= "~{outbase}.bam.bai"
    }

    runtime {
        docker : "~{minimapDocker}"
        disks : "local-disk ~{runtime_attributes.auto_diskGB} SSD"
        cpu : runtime_attributes.nThreads
        memory : "~{runtime_attributes.gbRAM} GB"
        hpcMemory : runtime_attributes.gbRAM
        hpcQueue : "~{runtime_attributes.hpcQueue}"
        hpcRuntimeMinutes : runtime_attributes.runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : runtime_attributes.maxPreemptAttempts
    }
}