# Copyright 2021 NVIDIA CORPORATION & AFFILIATES
version 1.0

import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/main/wdl/fq2bam.wdl" as ToBam

## Convert a BAM file into a pair of FASTQ files.
task bam2fq {
    input {
        File inputBAM
        File inputBAI
        File? originalRefTarball # Required for CRAM input
        String? ref # Name of FASTA reference file, required for CRAM input
        String pbPATH
        File? pbLicenseBin
        String pbDocker = "gcr.io/clara-lifesci/parabricks-cloud:4.0.0-1.beta1"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
    }

    String outbase = basename(inputBAM, ".bam")

    Int auto_diskGB = if diskGB == 0 then ceil(5.0 * size(inputBAM, "GB")) + ceil(size(inputBAI, "GB")) + 100 else diskGB

    command {
        ~{"tar xvf " + originalRefTarball + " && "}\
        time ~{pbPATH} bam2fq \
            --in-bam ~{inputBAM} \
            --out-prefix ~{outbase} \
            ~{"--license-file " + pbLicenseBin} \
            ~{"--ref " + ref} \
    }

    output {
        File outputFASTQ_1 = "${outbase}_1.fastq.gz"
        File outputFASTQ_2 = "${outbase}_2.fastq.gz"
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
        preemptible : 3
    }



}

workflow ClaraParabricks_bam2fq2bam {
    ## Given a BAM file,
    ## extract the reads from it and realign them to a new reference genome.
    ## Expected runtime for a 30X BAM is less than 3 hours on a 4x V100 system.
    ## We recommend running with at least 32 threads and 4x V100 GPUs.
    input {
        File inputBAM
        File inputBAI
        File? inputKnownSitesVCF
        File? inputKnownSitesTBI
        File? originalRefTarball  # for CRAM input
        File inputRefTarball
        File? pbLicenseBin
        String pbPATH
        String pbDocker = "gcr.io/clara-lifesci/parabricks-cloud:4.0.0-1.beta1"
        String tmpDir = "tmp_fq2bam"
        Int nGPU_fq2bam = 4
        String gpuModel_fq2bam = "nvidia-tesla-v100"
        String gpuDriverVersion_fq2bam = "460.73.01"
        Int nThreads_bam2fq = 12
        Int nThreads_fq2bam = 32
        Int gbRAM_bam2fq = 120
        Int gbRAM_fq2bam = 120
        Int diskGB = 0
        Int runtimeMinutes_bam2fq = 600
        Int runtimeMinutes_fq2bam = 600
        String hpcQueue_bam2fq = "norm"
        String hpcQueue_fq2bam = "gpu"
    }

    if (defined(originalRefTarball)){
        String ref = basename(select_first([originalRefTarball]), ".tar")
    }


    ## Run the BAM -> FASTQ conversion
    call bam2fq {
        input:
            inputBAM=inputBAM,
            inputBAI=inputBAI,
            originalRefTarball=originalRefTarball,
            ref=ref,
            pbPATH=pbPATH,
            pbLicenseBin=pbLicenseBin,
            nThreads=nThreads_bam2fq,
            gbRAM=gbRAM_bam2fq,
            runtimeMinutes=runtimeMinutes_bam2fq,
            hpcQueue=hpcQueue_bam2fq,
            diskGB=diskGB,
            pbDocker=pbDocker
    }

    ## Remap the reads from the bam2fq stage to the new reference to produce a BAM file.
    call ToBam.fq2bam as fq2bam {
        input:
            inputFASTQ_1=bam2fq.outputFASTQ_1,
            inputFASTQ_2=bam2fq.outputFASTQ_2,
            inputRefTarball=inputRefTarball,
            inputKnownSitesVCF=inputKnownSitesVCF,
            inputKnownSitesTBI=inputKnownSitesTBI,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPATH,
            nGPU=nGPU_fq2bam,
            nThreads=nThreads_fq2bam,
            gbRAM=gbRAM_fq2bam,
            runtimeMinutes=runtimeMinutes_fq2bam,
            gpuModel=gpuModel_fq2bam,
            gpuDriverVersion=gpuDriverVersion_fq2bam,
            diskGB=diskGB,
            tmpDir=tmpDir,
            hpcQueue=hpcQueue_fq2bam,
            pbDocker=pbDocker
    }

    output {
        File outputFASTQ_1 = bam2fq.outputFASTQ_1
        File outputFASTQ_2 = bam2fq.outputFASTQ_2
        File outputBAM = fq2bam.outputBAM
        File outputBAI = fq2bam.outputBAI
        File? outputBQSR = fq2bam.outputBQSR
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
