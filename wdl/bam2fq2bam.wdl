# Copyright 2021 NVIDIA CORPORATION & AFFILIATES
version 1.0

## Convert a BAM file into a pair of FASTQ files.
task bam2fq {
    input {
        File inputBAM
        File inputBAI
        File inputRefTarball
        String pbPATH
        File pbLicenseBin
        String pbDocker = "clara-parabricks/parabricks-cloud:4.0.0-1.alpha1"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
    }

    String ref = basename(inputRefTarball, ".tar")
    String outbase = basename(inputBAM, ".bam")

    Int auto_diskGB = if diskGB == 0 then ceil(2.5* size(inputBAM, "GB")) + ceil(size(inputRefTarball, "GB")) + ceil(size(inputBAI, "GB")) + 50 else diskGB

    command {
        time tar xf ${inputRefTarball} && \
        time ${pbPATH} bam2fq \
            --in-bam ${inputBAM} \
            --ref ${ref} \
            --out-prefix ${outbase} \
            --license-file ${pbLicenseBin}
    }

    output {
        File outputFQ_1 = "${outbase}_1.fastq.gz"
        File outputFQ_2 = "${outbase}_2.fastq.gz"
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

## Map the reads in a pair of FASTQ files to a reference,
## producing a BAM file with the default sample name of sample
## Also produces a BQSR report that can be used downstream for variant calling
## with HaplotypeCaller.
task fq2bam {
    input {
        File inputFQ_1
        File inputFQ_2
        File inputRefTarball
        File inputKnownSitesVCF
        File inputKnownSitesTBI
        File pbLicenseBin
        String pbPATH
        String pbDocker = "clara-parabricks/parabricks-cloud:4.0.0-1.alpha1"
        String tmp_dir = "tmp_fq2bam"
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-v100"
        String gpuDriverVersion = "460.73.01"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
    }

    Int auto_diskGB = if diskGB == 0 then ceil(2.5* size(inputFQ_1, "GB")) + ceil(size(inputRefTarball, "GB")) + ceil(size(inputKnownSitesVCF, "GB")) + 50 else diskGB

    String ref = basename(inputRefTarball, ".tar")
    String outbase = basename(inputFQ_1, "_1.fastq.gz")
    command {
        mkdir -p ${tmp_dir} && \
        time tar xf ${inputRefTarball} && \
        time ${pbPATH} fq2bam \
        --tmp-dir ${tmp_dir} \
        --in-fq ${inputFQ_1} ${inputFQ_2} \
        --ref ${ref} \
        --knownSites ${inputKnownSitesVCF} \
        --out-bam ${outbase}.pb.bam \
        --out-recal-file ${outbase}.pb.BQSR-REPORT.txt \
        --license-file ${pbLicenseBin}



    }

    output {
        File outputBAM = "${outbase}.pb.realn.bam"
        File outputBAI = "${outbase}.pb.realn.bam.bai"
        File outputBQSR = "${outbase}.BQSR-REPORT.txt"
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
        File knownSitesVCF
        File knownSitesTBI
        File originalRefTarball
        File inputRefTarball
        File pbLicenseBin
        String pbPATH
        String pbDocker = "clara-parabricks/parabricks-cloud:4.0.0-1.alpha1"
        String tmp_dir = "tmp_fq2bam"
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

    ## Run the BAM -> FASTQ conversion
    call bam2fq {
        input:
            inputBAM=inputBAM,
            inputBAI=inputBAI,
            inputRefTarball=originalRefTarball,
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
    call fq2bam {
        input:
            inputFQ_1=bam2fq.outputFQ_1,
            inputFQ_2=bam2fq.outputFQ_2,
            inputRefTarball=inputRefTarball,
            inputKnownSitesVCF=knownSitesVCF,
            inputKnownSitesTBI=knownSitesTBI,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPATH,
            nGPU=nGPU_fq2bam,
            nThreads=nThreads_fq2bam,
            gbRAM=gbRAM_fq2bam,
            runtimeMinutes=runtimeMinutes_fq2bam,
            gpuModel=gpuModel_fq2bam,
            gpuDriverVersion=gpuDriverVersion_fq2bam,
            diskGB=diskGB,
            tmp_dir=tmp_dir,
            hpcQueue=hpcQueue_fq2bam,
            pbDocker=pbDocker
    }

    output {
        File outputFQ_1 = bam2fq.outputFQ_1
        File outputFQ_2 = bam2fq.outputFQ_2
        File outputBAM = fq2bam.outputBAM
        File outputBAI = fq2bam.outputBAI
        File outputBQSR = fq2bam.outputBQSR
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
