version 1.0
# Copyright 2021 NVIDIA CORPORATION & AFFILIATES

task fq2bam {
    input {
        File inputFASTQ_1
        File inputFASTQ_2
        File inputRefTarball

        String? readGroup_sampleName = "SAMPLE"
        String? readGroup_libraryName = "LIB1"
        String? readGroup_ID = "RG1"
        String? readGroup_platformName = "ILLUMINA"
        String? readGroup_PU = "unit1"

        File? inputKnownSitesVCF
        File? inputKnownSitesTBI
        File? pbLicenseBin
        Boolean use_best_practices = false

        String pbPATH = "pbrun"
        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.1.0-1"
        String tmpDir = "tmp_fq2bam"
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-t4"
        String gpuDriverVersion = "460.73.01"
        Int nThreads = 32
        Int gbRAM = 180
        Int diskGB = 0
        String diskType = "SSD"
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
        Int maxPreemptAttempts = 3
    }

    Int auto_diskGB = if diskGB == 0 then ceil(5.0 * size(inputFASTQ_1, "GB")) + ceil(5.0 * size(inputFASTQ_2, "GB")) + ceil(3.0 * size(inputRefTarball, "GB")) + ceil(size(inputKnownSitesVCF, "GB")) + 150 else diskGB

    String best_practice_args = if use_best_practices then "--bwa-options \" -Y -K 100000000 \" " else ""

    String rgID = if readGroup_sampleName == "SAMPLE" then readGroup_ID else readGroup_sampleName + "-" + readGroup_ID

    String ref = basename(inputRefTarball, ".tar")
    String outbase = basename(basename(basename(basename(inputFASTQ_1, ".gz"), ".fastq"), ".fq"), "_1")
    command {
        set -e
        set -x
        set -o pipefail
        mkdir -p ~{tmpDir} && \
        time tar xf ~{inputRefTarball} && \
        time ~{pbPATH} fq2bam \
        --tmp-dir ~{tmpDir} \
        --in-fq ~{inputFASTQ_1} ~{inputFASTQ_2} \
        "@RG\tID:~{rgID}\tLB:~{readGroup_libraryName}\tPL:~{readGroup_platformName}\tSM:~{readGroup_sampleName}\tPU:~{readGroup_PU}" \
        ~{best_practice_args} \
        --ref ~{ref} \
        ~{"--knownSites " + inputKnownSitesVCF + " --out-recal-file " + outbase + ".pb.BQSR-REPORT.txt"} \
        --out-bam ~{outbase}.pb.bam \
        ~{"--license-file " + pbLicenseBin}
    }

    output {
        File outputBAM = "~{outbase}.pb.bam"
        File outputBAI = "~{outbase}.pb.bam.bai"
        File? outputBQSR = "~{outbase}.pb.BQSR-REPORT.txt"
    }

    runtime {
        docker : "~{pbDocker}"
        disks : "local-disk ~{auto_diskGB} ~{diskType}"
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
        String? readGroup_sampleName = "SAMPLE"
        String? readGroup_libraryName = "LIB1"
        String? readGroup_ID = "RG1"
        String? readGroup_platformName = "ILMN"
        String? readGroup_PU = "Barcode1"
        File inputRefTarball
        File? inputKnownSitesVCF
        File? inputKnownSitesTBI
        File? pbLicenseBin
        String pbPATH = "pbrun"
        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.1.0-1"
        String tmpDir = "tmp_fq2bam"
        String gpuModel = "nvidia-tesla-t4"
        Int nGPU = 4
        Int nThreads = 32
        Int gbRAM = 180
        Int diskGB = 0
        String diskType = "SSD"
        Int runtimeMinutes = 600
        Int maxPreemptAttempts = 3
    }
    
    call fq2bam {
        input:
            inputFASTQ_1=inputFASTQ_1,
            inputFASTQ_2=inputFASTQ_2,
            inputRefTarball=inputRefTarball,
            inputKnownSitesVCF=inputKnownSitesVCF,
            inputKnownSitesTBI=inputKnownSitesTBI,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPATH,
            readGroup_sampleName=readGroup_sampleName,
            readGroup_libraryName=readGroup_libraryName,
            readGroup_ID=readGroup_ID,
            readGroup_platformName=readGroup_platformName,
            pbDocker=pbDocker,
            tmpDir=tmpDir,
            nGPU=nGPU,
            gpuModel=gpuModel,
            nThreads=nThreads,
            gbRAM=gbRAM,
            diskGB=diskGB,
            diskType=diskType,
            runtimeMinutes=runtimeMinutes,
            maxPreemptAttempts=maxPreemptAttempts
    }

    output {
        File outputBAM = fq2bam.outputBAM
        File outputBAI = fq2bam.outputBAI
        File? outputBQSR = fq2bam.outputBQSR
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}