version 1.0
# Copyright 2023 NVIDIA CORPORATION & AFFILIATES

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

        Int diskGB = 0
        String pbmm2Docker = "erictdawson/pbmm2"
        Int gbRAM = 62
        String hpcQueue = "norm"
        Int runtimeMinutes = 240
        Int maxPreemptAttempts = 3  
    }

    Int sort_threads = 4
    ## Put a ceiling on mm2_threads so as not to oversubscribe our VM
    ## mm2_threads = min(mapThreads, nThreads - sort_threads - 1)
    Int mm2_threads = if nThreads - sort_threads >= mapThreads then mapThreads else nThreads - sort_threads -1
    String outbase = basename(basename(basename(inputFASTQ, ".gz"), ".fq"), ".fastq")
    Int auto_diskGB = if diskGB == 0 then ceil(size(inputFASTQ, "GB") * 3.2) + ceil(size(inputReference, "GB") * 3) + 80 else diskGB

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

task minimap2 {
    input {
        File inputFASTQ
        File inputReference
        File? referenceIndex
        String sampleName
        String mm2Preset = "map-ont"
        Int nThreads = 32
        Int mapThreads = 28

        Int diskGB = 0
        String minimapDocker = "erictdawson/minimap2"
        Int gbRAM = 62
        String hpcQueue = "norm"
        Int runtimeMinutes = 240
        Int maxPreemptAttempts = 3
    }

    Int sort_threads = 4
    ## Put a ceiling on mm2_threads so as not to oversubscribe our VM
    ## mm2_threads = min(mapThreads, nThreads - sort_threads - 1)
    Int mm2_threads = if nThreads - sort_threads >= mapThreads then mapThreads else nThreads - sort_threads -1
    String outbase = basename(basename(basename(inputFASTQ, ".gz"), ".fq"), ".fastq")
    Int auto_diskGB = if diskGB == 0 then ceil(size(inputFASTQ, "GB") * 3.2) + ceil(size(inputReference, "GB") * 3) + 80 else diskGB

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