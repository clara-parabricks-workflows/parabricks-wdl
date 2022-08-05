# Copyright 2021 NVIDIA CORPORATION & AFFILIATES
version 1.0

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


task indexFASTA {
    input {
        File inputFASTA
        String samtoolsPATH = "samtools"
        String bwaPATH = "bwa"
        String indexDocker = "clara-parabricks/bwa"
        Int nThreads = 3
        Int gbRAM = 22
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "norm"
    }
    String localFASTA = basename(inputFASTA)
    Int auto_diskGB = if diskGB == 0 then ceil(2.5* size(inputFASTA, "GB")) + 50 else diskGB

    command {
        cp ~{inputFASTA} . && \
        ~{samtoolsPATH} faidx ~{localFASTA} && \
        ~{bwaPATH} index ~{localFASTA} && \
        tar cvf ~{localFASTA}.tar ~{localFASTA}*
    }
    output {
        File outputRefTarball = "~{localFASTA}.tar"
    }
    runtime {
        docker : "~{indexDocker}"
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

workflow ClaraParabricks_GenerateRegionTestData {
    ## Given a BAM file and a samtools-style region
    ## create a miniaturized reference + ref index tarball and
    ## a matched bam / fastq pair for the region.
    input {
        File inputBAM
        File inputBAI
        String inputRegion
        File knownSitesVCF
        File knownSitesTBI
        File inputRefTarball
        File pbLicenseBin
        String pbPATH
        String pbDocker = "us-docker.pkg.dev/clara-lifesci/nv-parabricks-test/parabricks-cloud:4.0.0-1.alpha1"
        
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
    call reduceFASTA{
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

    call indexFASTA {
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
    call reduceVCF {
        input:
            inputVCF=knownSitesVCF,
            inputTBI=knownSitesTBI,
            region=inputRegion,
            bcftoolsPATH=bcftoolsPATH,
            bcftoolsDocker=bcftoolsDocker
    } 
    call reduceBAM {
        input:
            inputBAM=inputBAM,
            inputBAI=inputBAI,
            region=inputRegion,
            samtoolsPATH=samtoolsPATH,
            samtoolsDocker=samtoolsDocker
    }
    call bam2fq {
        input:
            inputBAM=reduceBAM.outputBAM,
            inputBAI=reduceBAM.outputBAI,
            inputRefTarball=indexFASTA.outputRefTarball,
            pbPATH=pbPATH,
            pbLicenseBin=pbLicenseBin,
            nThreads=nThreads_bam2fq,
            gbRAM=gbRAM_bam2fq,
            runtimeMinutes=runtimeMinutes_bam2fq,
            hpcQueue=hpcQueue_bam2fq,
            diskGB=diskGB,
            pbDocker=pbDocker
    }
    call fq2bam {
        input:
            inputFQ_1=bam2fq.outputFQ_1,
            inputFQ_2=bam2fq.outputFQ_2,
            inputRefTarball=indexFASTA.outputRefTarball,
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
        File outputRefTarball = indexFASTA.outputRefTarball
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
