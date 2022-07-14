version 1.0
# Copyright 2021 NVIDIA CORPORATION & AFFILIATES

task fq2bam {
    input {
        File inputFASTQ_1
        File inputFASTQ_2
        String? sampleName 
        String? libraryName 
        String? readGroupName 
        String? platformName 
        File inputRefTarball
        File inputKnownSites
        File inputKnownSitesTBI
        File pbLicenseBin
        String pbPATH
        String pbDocker = "parabricks-cloud:latest"
        String tmpDir = "tmp_fq2bam"
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-v100"
        String gpuDriverVersion = "460.73.01"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
        Int maxPreemptAttempts = 3
    }

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputFASTQ_1, "GB")) + ceil(size(inputFASTQ_2, "GB")) + ceil(size(inputRefTarball, "GB")) + ceil(size(inputKnownSites, "GB")) + ceil(3.0 * size(inputFASTQ_1, "GB")) + 50 else diskGB


    String ref = basename(inputRefTarball, ".tar")
    String outbase = basename(basename(basename(basename(inputFASTQ_1, ".gz"), ".fastq"), ".fq"), "_1")
    command {
        mkdir -p ~{tmpDir} && \
        time tar xf ~{inputRefTarball} && \
        time ~{pbPATH} fq2bam \
        --tmp-dir ~{tmpDir} \
        --in-fq ~{inputFASTQ_1} ~{inputFASTQ_2} \
        ~{"--read-group-sm " + sampleName} \
        ~{"--read-group-lb " + libraryName} \
        ~{"--read-group-pl " + platformName} \
        ~{"--read-group-id-prefix " + readGroupName} \
        --ref ~{ref} \
        --knownSites ~{inputKnownSites} \
        --out-bam ~{outbase}.bam \
        --out-recal-file ~{outbase}.BQSR-REPORT.txt \
        --license-file ~{pbLicenseBin}
    }

    output {
        File outputBAM = "~{outbase}.pb.realn.bam"
        File outputBAI = "~{outbase}.pb.realn.bam.bai"
        File outputBQSR = "~{outbase}.BQSR-REPORT.txt"
    }

    runtime {
        docker : "~{pbDocker}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : nThreads
        memory : "~{gbRAM} GB"
        hpcMemory : gbRAM
        hpcQueue : "~{hpcQueue}"
        hpcRuntimeMinutes : runtimeMinutes
        gpuType : "~{gpuModel}"
        gpuCount : nGPU
        nvidiaDriverVersion : "~{gpuDriverVersion}"
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : maxPreemptAttempts
    }
}

workflow Parabricks_FQ2BAM {

    input {
        File inputFASTQ_1
        File inputFASTQ_2
        String? sampleName 
        String? libraryName
        String? readGroupName 
        String? platformName
        File inputRefTarball
        File inputKnownSites
        File inputKnownSitesTBI
        File pbLicenseBin
        String pbPATH
        String pbDocker = "parabricks-cloud:latest"
        String tmpDir = "tmp_fq2bam"
        String gpuModel = "nvidia-tesla-v100"
        Int nGPU = 4
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        Int maxPreemptAttempts = 3
    }

    ## Automatically size disk if diskGB is 0.
    ## Otherwise, use the value provided for diskGB.
    
    call fq2bam as fq2b {
        input:
            inputFASTQ_1=inputFASTQ_1,
            inputFASTQ_2=inputFASTQ_2,
            inputRefTarball=inputRefTarball,
            inputKnownSites=inputKnownSites,
            inputKnownSitesTBI=inputKnownSitesTBI,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPATH,
            sampleName=sampleName,
            libraryName=libraryName,
            readGroupName=readGroupName,
            platformName=platformName,
            pbDocker=pbDocker,
            tmpDir=tmpDir,
            nGPU=nGPU,
            gpuModel=gpuModel,
            nThreads=nThreads,
            gbRAM=gbRAM,
            diskGB=diskGB,
            runtimeMinutes=runtimeMinutes,
            maxPreemptAttempts=maxPreemptAttempts
    }

    output {
        File outputBAM = fq2b.outputBAM
        File outputBAI = fq2b.outputBAI
        File outputBQSR = fq2b.outputBQSR
    }
}