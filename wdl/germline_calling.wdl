version 1.0

task haplotypecaller {
    input {
        File inputBAM
        File inputBAI
        File? inputRecal
        File inputRefTarball
        Boolean gvcfMode = false
        String? haplotypecallerPassthroughOptions
        String pbPATH
        File? pbLicenseBin
        String? pbDocker
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

    String outbase = basename(inputBAM, ".bam")
    String ref = basename(inputRefTarball, ".tar")

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputBAM, "GB")) + ceil(size(inputRefTarball, "GB")) + ceil(size(inputBAI, "GB")) + 65 else diskGB

    String outVCF = outbase + ".haplotypecaller" + (if gvcfMode then '.g' else '') + ".vcf"

    command {
        time tar xvf ~{inputRefTarball} && \
        time ~{pbPATH} haplotypecaller \
        ~{if gvcfMode then "--gvcf " else ""} \
        ~{"--haplotypecaller-options " + '"' + haplotypecallerPassthroughOptions + '"'} \
        --in-bam ~{inputBAM} \
        --ref ~{ref} \
        ~{"--in-recal-file " + inputRecal} \
        --out-variants ~{outVCF} \
        ~{"--license-file " + pbLicenseBin} && \
        bgzip -@ ~{nThreads} ~{outVCF} && \
        tabix ~{outVCF}.gz
    }

    output {
        File haplotypecallerVCF = "~{outVCF}.gz"
        File haplotypecallerTBI = "~{outVCF}.gz.tbi"
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

task deepvariant {
    input {
        File inputBAM
        File inputBAI
        File inputRefTarball
        String pbPATH
        File? pbLicenseBin
        String? pbDocker
        Boolean gvcfMode = false
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

    String ref = basename(inputRefTarball, ".tar")
    String outbase = basename(inputBAM, ".bam")

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputBAM, "GB")) + ceil(size(inputRefTarball, "GB")) + ceil(size(inputBAI, "GB")) + 65 else diskGB

    String outVCF = outbase + ".deepvariant" + (if gvcfMode then '.g' else '') + ".vcf"


    command {
        time tar xf ${inputRefTarball} && \
        time ${pbPATH} deepvariant \
        ~{if gvcfMode then "--gvcf " else ""} \
        --ref ${ref} \
        --in-bam ${inputBAM} \
        --out-variants ~{outVCF} \
        ~{"--license-file " + pbLicenseBin} && \
        bgzip -@ ~{nThreads} ~{outVCF} && \
        tabix ~{outVCF}.gz
    }

    output {
        File deepvariantVCF = "~{outVCF}.gz"
        File deepvariantTBI = "~{outVCF}.gz.tbi"
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

workflow ClaraParabricks_Germline {
    input {
        File inputBAM
        File inputBAI
        File? inputRecal

        File inputRefTarball
        File? pbLicenseBin
        String pbPATH
        String pbDocker = "gcr.io/clara-lifesci/parabricks-cloud:4.0.0-1.alpha1"

        ## Run both DeepVariant and HaplotypeCaller in gVCF mode
        Boolean gvcfMode = false

        ## Universal preemptible limit
        Int maxPreemptAttempts = 3

        ## DeepVariant Runtime Args
        Int nGPU_DeepVariant = 4
        String gpuModel_DeepVariant = "nvidia-tesla-v100"
        String gpuDriverVersion_DeepVariant = "460.73.01"
        Int nThreads_DeepVariant = 32
        Int gbRAM_DeepVariant = 120
        Int diskGB_DeepVariant = 0
        Int runtimeMinutes_DeepVariant = 600
        String hpcQueue_DeepVariant = "gpu"

        ## HaplotypeCaller Runtime Args
        String? haplotypecallerPassthroughOptions
        Int nGPU_HaplotypeCaller = 4
        String gpuModel_HaplotypeCaller = "nvidia-tesla-v100"
        String gpuDriverVersion_HaplotypeCaller = "460.73.01"
        Int nThreads_HaplotypeCaller = 32
        Int gbRAM_HaplotypeCaller = 120
        Int diskGB_HaplotypeCaller = 0
        Int runtimeMinutes_HaplotypeCaller = 600
        String hpcQueue_HaplotypeCaller = "gpu"
    }

    call haplotypecaller {
        input:
            inputBAM=inputBAM,
            inputBAI=inputBAI,
            inputRecal=inputRecal,
            inputRefTarball=inputRefTarball,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPATH,
            gvcfMode=gvcfMode,
            haplotypecallerPassthroughOptions=haplotypecallerPassthroughOptions,
            nThreads=nThreads_HaplotypeCaller,
            nGPU=nGPU_HaplotypeCaller,
            gpuModel=gpuModel_HaplotypeCaller,
            gpuDriverVersion=gpuDriverVersion_HaplotypeCaller,
            gbRAM=gbRAM_HaplotypeCaller,
            diskGB=diskGB_HaplotypeCaller,
            runtimeMinutes=runtimeMinutes_HaplotypeCaller,
            hpcQueue=hpcQueue_HaplotypeCaller,
            pbDocker=pbDocker,
            maxPreemptAttempts=maxPreemptAttempts
    }

    call deepvariant {
        input:
            inputBAM=inputBAM,
            inputBAI=inputBAI,
            inputRefTarball=inputRefTarball,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPATH,
            gvcfMode=gvcfMode,
            nThreads=nThreads_DeepVariant,
            nGPU=nGPU_DeepVariant,
            gpuModel=gpuModel_DeepVariant,
            gpuDriverVersion=gpuDriverVersion_DeepVariant,
            gbRAM=gbRAM_DeepVariant,
            diskGB=diskGB_DeepVariant,
            runtimeMinutes=runtimeMinutes_DeepVariant,
            hpcQueue=hpcQueue_DeepVariant,
            pbDocker=pbDocker,
            maxPreemptAttempts=maxPreemptAttempts
    }

    output {
        File deepvariantVCF = deepvariant.deepvariantVCF
        File deepvariantTBI = deepvariant.deepvariantTBI
        File haplotypecallerVCF = haplotypecaller.haplotypecallerVCF
        File haplotypecallerTBI = haplotypecaller.haplotypecallerTBI
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
