version 1.0

task haplotypecaller {
    input {
        File inputBAM
        File inputBAI
        File? inputRecal
        File inputRefTarball
        String pbPATH = "pbrun"
        File? intervalFile
        Boolean gvcfMode = false
        Boolean useBestPractices = false
        String? haplotypecallerPassthroughOptions = ""
        String annotationArgs = ""

        File? pbLicenseBin
        String? pbDocker
        Int nGPU = 2
        String gpuModel = "nvidia-tesla-t4"
        String gpuDriverVersion = "525.60.13"
        Int nThreads = 24
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
        Int maxPreemptAttempts = 3
    }

    String outbase = basename(inputBAM, ".bam")
    String localTarball = basename(inputRefTarball)
    String ref = basename(inputRefTarball, ".tar")

    Int auto_diskGB = if diskGB == 0 then ceil(2.0 * size(inputBAM, "GB")) + ceil(2.0 * size(inputRefTarball, "GB")) + ceil(size(inputBAI, "GB")) + 120 else diskGB

    String outVCF = outbase + ".haplotypecaller" + (if gvcfMode then '.g' else '') + ".vcf"

    String quantization_band_stub = if useBestPractices then " -GQB 10 -GQB 20 -GQB 30 -GQB 40 -GQB 50 -GQB 60 -GQB 70 -GQB 80 -GQB 90 " else ""
    String quantization_qual_stub = if useBestPractices then " --static-quantized-quals 10 --static-quantized-quals 20 --static-quantized-quals 30" else ""
    String annotation_stub_base = if useBestPractices then "-G StandardAnnotation -G StandardHCAnnotation" else annotationArgs
    String annotation_stub = if useBestPractices && gvcfMode then annotation_stub_base + " -G AS_StandardAnnotation " else annotation_stub_base

    command <<<
        mv ~{inputRefTarball} ~{localTarball} && \
        time tar xvf ~{localTarball} && \
        time ~{pbPATH} haplotypecaller \
        --in-bam ~{inputBAM} \
        --ref ~{ref} \
        --out-variants ~{outVCF} \
        ~{"--in-recal-file " + inputRecal} \
        ~{if gvcfMode then "--gvcf " else ""} \
        ~{"--haplotypecaller-options " + '"' + haplotypecallerPassthroughOptions + '"'} \
        ~{annotation_stub} \
        ~{quantization_band_stub} \
        ~{quantization_qual_stub} \
        ~{"--license-file " + pbLicenseBin}
    >>>

    output {
        File haplotypecallerVCF = "~{outVCF}"
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
        String pbPATH = "pbrun"
        File? pbLicenseBin
        String? pbDocker
        Boolean gvcfMode = false
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-t4"
        String gpuDriverVersion = "525.60.13"
        Int nThreads = 24
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
        Int maxPreemptAttempts = 3
    }

    String ref = basename(inputRefTarball, ".tar")
    String localTarball = basename(inputRefTarball)
    String outbase = basename(inputBAM, ".bam")

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputBAM, "GB")) + ceil(size(inputRefTarball, "GB")) + ceil(size(inputBAI, "GB")) + 65 else diskGB

    String outVCF = outbase + ".deepvariant" + (if gvcfMode then '.g' else '') + ".vcf"


    command <<<
        mv ~{inputRefTarball} ~{localTarball} && \
        time tar xvf ~{localTarball} && \
        time ~{pbPATH} deepvariant \
        ~{if gvcfMode then "--gvcf " else ""} \
        --ref ~{ref} \
        --in-bam ~{inputBAM} \
        --out-variants ~{outVCF} \
        ~{"--license-file " + pbLicenseBin}
    >>>

    output {
        File deepvariantVCF = "~{outVCF}"
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
        String pbPATH = "pbrun"

        File? pbLicenseBin
        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.3.0-1"

        Boolean runDeepVariant = true
        Boolean runHaplotypeCaller = true
        ## Run both DeepVariant and HaplotypeCaller in gVCF mode
        Boolean gvcfMode = false

        ## Universal preemptible limit
        Int maxPreemptAttempts = 3

        ## DeepVariant Runtime Args
        Int nGPU_DeepVariant = 4
        String gpuModel_DeepVariant = "nvidia-tesla-t4"
        String gpuDriverVersion_DeepVariant = "525.60.13"
        Int nThreads_DeepVariant = 24
        Int gbRAM_DeepVariant = 120
        Int diskGB_DeepVariant = 0
        Int runtimeMinutes_DeepVariant = 600
        String hpcQueue_DeepVariant = "gpu"

        ## HaplotypeCaller Runtime Args
        String? haplotypecallerPassthroughOptions
        Int nGPU_HaplotypeCaller = 2
        String gpuModel_HaplotypeCaller = "nvidia-tesla-t4"
        String gpuDriverVersion_HaplotypeCaller = "525.60.13"
        Int nThreads_HaplotypeCaller = 24
        Int gbRAM_HaplotypeCaller = 120
        Int diskGB_HaplotypeCaller = 0
        Int runtimeMinutes_HaplotypeCaller = 600
        String hpcQueue_HaplotypeCaller = "gpu"
    }

    if (runHaplotypeCaller){
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

    }

    if (runDeepVariant){
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
    }

    output {
        File? deepvariantVCF = deepvariant.deepvariantVCF
        File? haplotypecallerVCF = haplotypecaller.haplotypecallerVCF
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
