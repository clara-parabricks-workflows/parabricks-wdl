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
        --out-bam ~{outbase}.pb.bam \
        --out-recal-file ~{outbase}.pb.BQSR-REPORT.txt \
        --license-file ~{pbLicenseBin}
    }

    output {
        File outputBAM = "~{outbase}.pb.bam"
        File outputBAI = "~{outbase}.pb.bam.bai"
        File outputBQSR = "~{outbase}.pb.BQSR-REPORT.txt"
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

workflow ClaraParabricks_fq2bam {

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
    
    call fq2bam {
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
        File outputBAM = fq2bam.outputBAM
        File outputBAI = fq2bam.outputBAI
        File outputBQSR = fq2bam.outputBQSR
    }
}