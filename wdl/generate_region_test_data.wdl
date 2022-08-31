# Copyright 2021 NVIDIA CORPORATION & AFFILIATES
version 1.0

import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/main/wdl/build_reference_indices.wdl" as CPB_indexFasta
import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/main/wdl/bam2fq2bam.wdl" as CPB_bam2fq
import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/main/wdl/fq2bam.wdl" as CPB_fq2bam


task reduceVCF {
    input {
        File inputVCF
        File inputTBI
        String region
        String bcftoolsPATH = "bcftools"
        String bcftoolsDocker = "claraparabricks/bcftools"
        Int nThreads = 4
        Int gbRAM = 16
        Int diskGB = 0
        Int runtimeMinutes = 60
        String hpcQueue = "norm"
        Int maxPreemptAttempts = 3
    }
    String outbase = basename(inputVCF)
    Int auto_diskGB = if diskGB == 0 then ceil(size(inputVCF, "GB")) + 50 else diskGB

    command {
        ~{bcftoolsPATH} view -O z -o ~{region}.~{outbase} ~{inputVCF} ~{region} && \
        tabix ~{region}.~{outbase}
    }
    output {
        File outputVCF = "~{region}.~{outbase}"
        File outputTBI = "~{region}.~{outbase}.tbi"
    }
    runtime {
        docker : "~{bcftoolsDocker}"
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

task reduceBAM {
    input {
        File inputBAM
        File inputBAI
        String region
        String samtoolsPATH = "samtools"
        String samtoolsDocker = "claraparabricks/samtools"
        Int nThreads = 3
        Int gbRAM = 12
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "norm"
        Int maxPreemptAttempts = 3
    }
    String outbase = basename(inputBAM)
    Int auto_diskGB = if diskGB == 0 then ceil(size(inputBAM, "GB")) + 50 else diskGB

    command {
        ~{samtoolsPATH} view -b -o ~{region}.~{outbase} ~{inputBAM} ~{region} && \
        ~{samtoolsPATH} index ~{region}.~{outbase}
    }
    output {
        File outputBAM = "~{region}.~{outbase}"
        File outputBAI = "~{region}.~{outbase}.bai"
    }
    runtime {
        docker : "~{samtoolsDocker}"
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


task reduceFASTA {
    input {
        File inputRefTarball
        String inputRegion
        String samtoolsPATH = "samtools"
        String samtoolsDocker = "claraparabricks/samtools"
        Int nThreads = 4
        Int gbRAM = 15
        Int diskGB = 0
        Int runtimeMinutes = 60
        String hpcQueue = "norm"
        Int maxPreemptAttempts = 3
    }
    String outbase = basename(inputRefTarball, ".tar")
    Int auto_diskGB = if diskGB == 0 then ceil(size(inputRefTarball, "GB")) + 50 else diskGB

    command {
        tar xvf ~{inputRefTarball} && \
        ~{samtoolsPATH} faidx ~{outbase} ~{inputRegion} > ~{inputRegion}.~{outbase}
    }
    output {
        File outputFASTA = "~{inputRegion}.~{outbase}"
    }
    runtime {
        docker : "~{samtoolsDocker}"
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

workflow ClaraParabricks_GenerateRegionTestData {
    ## Given a BAM file and a samtools-style region
    ## create a miniaturized reference + ref index tarball and
    ## a matched bam / fastq pair for the region.
    input {
        File inputBAM
        File inputBAI
        String inputRegion
        File? knownSitesVCF
        File? knownSitesTBI
        File inputRefTarball
        File? pbLicenseBin
        String pbPATH
        String pbDocker = "gcr.io/clara-lifesci/parabricks-cloud:4.0.0-1.beta3"
        
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


        Int nThreads_reduceFASTA = 4
        Int gbRAM_reduceFASTA = 15
        Int diskGB_reduceFASTA = 0
        Int runtimeMinutes_reduceFASTA = 60
        String hpcQueue_reduceFASTA = "norm"

        String bcftoolsPATH = "bcftools"
        String bcftoolsDocker = "claraparabricks/bcftools"

        String samtoolsPATH = "samtools"
        String samtoolsDocker = "claraparabricks/samtools"


        ## must contain samtools + BWA + bgzip + tabix
        String indexDocker = "claraparabricks/bwa"
        String bwaPATH = "bwa"
        Int nThreads_indexFASTA = 14
        Int gbRAM_indexFASTA = 64
        Int runtimeMinutes_indexFASTA = 600


    }

    ## Reduce our reference file
    call reduceFASTA {
        input:
            inputRefTarball=inputRefTarball,
            inputRegion=inputRegion,
            samtoolsPATH=samtoolsPATH,
            samtoolsDocker=samtoolsDocker,
            nThreads=nThreads_reduceFASTA,
            gbRAM=gbRAM_reduceFASTA,
            diskGB=diskGB_reduceFASTA,
            runtimeMinutes=runtimeMinutes_reduceFASTA,
            hpcQueue=hpcQueue_reduceFASTA
    }

    call CPB_indexFasta.index as indexFASTA {
        input:
            inputFASTA=reduceFASTA.outputFASTA,
            samtoolsPATH=samtoolsPATH,
            bwaPATH=bwaPATH,
            indexDocker=indexDocker,
            nThreads=nThreads_indexFASTA,
            gbRAM=gbRAM_indexFASTA,
            diskGB=diskGB_reduceFASTA,
            runtimeMinutes=runtimeMinutes_indexFASTA,
            hpcQueue=hpcQueue_reduceFASTA
    }

    ## Shrink and index the knownSites VCF file
    if (defined(knownSitesVCF)){
        call reduceVCF {
            input:
                inputVCF=select_first([knownSitesVCF]),
                inputTBI=select_first([knownSitesTBI]),
                region=inputRegion,
                bcftoolsPATH=bcftoolsPATH,
                bcftoolsDocker=bcftoolsDocker
        }
    }
 

    call reduceBAM {
        input:
            inputBAM=inputBAM,
            inputBAI=inputBAI,
            region=inputRegion,
            samtoolsPATH=samtoolsPATH,
            samtoolsDocker=samtoolsDocker
    }

    call CPB_bam2fq.bam2fq as bam2fq {
        input:
            inputBAM=reduceBAM.outputBAM,
            inputBAI=reduceBAM.outputBAI,
            pbPATH=pbPATH,
            pbLicenseBin=pbLicenseBin,
            nThreads=nThreads_bam2fq,
            gbRAM=gbRAM_bam2fq,
            runtimeMinutes=runtimeMinutes_bam2fq,
            hpcQueue=hpcQueue_bam2fq,
            diskGB=diskGB,
            pbDocker=pbDocker
    }

    call CPB_fq2bam.fq2bam as fq2bam {
        input:
            inputFASTQ_1=bam2fq.outputFASTQ_1,
            inputFASTQ_2=bam2fq.outputFASTQ_2,
            inputRefTarball=inputRefTarball,
            inputKnownSitesVCF=reduceVCF.outputVCF,
            inputKnownSitesTBI=reduceVCF.outputTBI,
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
        File outputFQ_1 = bam2fq.outputFASTQ_1
        File outputFQ_2 = bam2fq.outputFASTQ_2
        File outputBAM = fq2bam.outputBAM
        File outputBAI = fq2bam.outputBAI
        File? outputBQSR = fq2bam.outputBQSR
        File outputRefTarball = indexFASTA.refTarball
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
