# Copyright 2022 NVIDIA CORPORATION & AFFILIATES
version 1.0

task mutect2_call {
    input {
        File tumorBAM
        File tumorBAI
        String tumorName
        File normalBAM
        File normalBAI
        String normalName
        File inputRefTarball
        File? intervalFile
        File? tumorBQSR
        File? normalBQSR
        String pbPATH = "pbrun"
        File? pbLicenseBin
        File? ponFile
        File? ponVCF
        File? ponTBI
        String? pbDocker
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-t4"
        String gpuDriverVersion = "460.73.01"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
        Int maxPreemptAttempts = 3
    }

    String ref = basename(inputRefTarball, ".tar")
    String outbase = basename(tumorBAM, ".bam") + "." + basename(normalBAM, ".bam") + ".mutectcaller"

    Int auto_diskGB = if diskGB == 0 then ceil(2.0 * size(tumorBAM, "GB")) + ceil(size(normalBAM, "GB")) + ceil(3.0 * size(inputRefTarball, "GB")) + 120 else diskGB

    command {
        time tar xf ~{inputRefTarball} && \
        time ~{pbPATH} mutectcaller \
        --ref ~{ref} \
        --tumor-name ~{tumorName} \
        ~{"--in-tumor-recal-file " + tumorBQSR} \
        --in-tumor-bam ~{tumorBAM} \
        --normal-name ~{normalName} \
        --in-normal-bam ~{normalBAM} \
        ~{"--in-normal-recal-file " + normalBQSR} \
        ~{"--pon " + ponVCF} \
        ~{"--interval-file " + intervalFile} \
        ~{"--license-file " + pbLicenseBin} \
        --out-vcf ~{outbase}.vcf
    }
    output {
        File outputVCF = "~{outbase}.vcf"
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

task mutect2_postpon {
    input {
        File inputVCF
        File ponFile
        File ponVCF
        File ponTBI
        String pbPATH = "pbrun"
        File? pbLicenseBin
        String? pbDocker
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-t4"
        String gpuDriverVersion = "460.73.01"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
        Int maxPreemptAttempts = 3
    }
    Int auto_diskGB = if diskGB == 0 then ceil(3.0 * size(inputVCF, "GB") * 2.5) + ceil(size(ponFile, "GB")) + ceil(size(ponVCF, "GB"))  + 120 else diskGB

    String outbase = basename(basename(inputVCF, ".gz"), ".vcf")

    command {
        time ${pbPATH} postpon \
        --in-vcf ~{inputVCF} \
        --in-pon-file ~{ponVCF} \
        --out-vcf ~{outbase}.postpon.vcf
    }
    output {
        File outputVCF = "~{outbase}.postpon.vcf"
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

task compressAndIndexVCF {
    input {
        File inputVCF
        String bgzipDocker = "claraparabricks/samtools"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "norm"
        Int maxPreemptAttempts = 3
    }
    Int auto_diskGB = if diskGB == 0 then ceil(3.0 * size(inputVCF, "GB") * 2.0) + 40 else diskGB
    ## We need to write to stdout in our task, as bgzip will compress the file in-place on the
    ## mounted volume and not the local disk. The issue with this is the mounted volume is not visible
    ## when searching for outputs.
    String localVCF = basename(inputVCF)
    command {
        bgzip -c -@ ~{nThreads} ~{inputVCF} > ~{localVCF}.gz  && \
        tabix ~{localVCF}.gz
    }
    output {
        File outputVCF = "~{localVCF}.gz"
        File outputTBI = "~{localVCF}.gz.tbi"
    }
    runtime {
        docker : "~{bgzipDocker}"
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

workflow ClaraParabricks_Somatic {
    input {
        File tumorBAM
        File tumorBAI
        File? tumorBQSR
        String tumorName
        File normalBAM
        File normalBAI
        File? normalBQSR
        String normalName
        File inputRefTarball
        String pbPATH = "pbrun"
        File? pbLicenseBin
        File? ponVCF
        File? ponTBI
        File? ponFile
        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.1.0-1"
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-t4"
        String gpuDriverVersion = "460.73.01"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
        Int maxPreemptAttempts = 3
    }

    Boolean doPON = defined(ponVCF)

    if (doPON){
        call mutect2_call as pb_mutect2_pon {
            input:
                tumorBAM=tumorBAM,
                tumorBAI=tumorBAI,
                tumorName=tumorName,
                normalBAM=normalBAM,
                normalBAI=normalBAI,
                normalName=normalName,
                inputRefTarball=inputRefTarball,
                ponFile=ponFile,
                ponVCF=ponVCF,
                ponTBI=ponTBI,
                pbPATH=pbPATH,
                pbLicenseBin=pbLicenseBin,
                pbDocker=pbDocker,
                nGPU=nGPU,
                gpuModel=gpuModel,
                gpuDriverVersion=gpuDriverVersion,
                nThreads=nThreads,
                gbRAM=gbRAM,
                diskGB=diskGB,
                runtimeMinutes=runtimeMinutes,
                hpcQueue=hpcQueue,
                maxPreemptAttempts=maxPreemptAttempts
        }
        call mutect2_postpon {
            input:
                inputVCF=pb_mutect2_pon.outputVCF,
                ponFile=select_first([ponFile]),
                ponVCF=select_first([ponVCF]),
                ponTBI=select_first([ponTBI]),
                pbPATH=pbPATH,
                pbLicenseBin=pbLicenseBin,
                pbDocker=pbDocker,
                nGPU=nGPU,
                gpuModel=gpuModel,
                gpuDriverVersion=gpuDriverVersion,
        }
    }
    if (!doPON){
        call mutect2_call as pb_mutect2_withoutPON {
            input:
                tumorBAM=tumorBAM,
                tumorBAI=tumorBAI,
                tumorName=tumorName,
                normalBAM=normalBAM,
                normalBAI=normalBAI,
                normalName=normalName,
                inputRefTarball=inputRefTarball,
                pbPATH=pbPATH,
                pbLicenseBin=pbLicenseBin,
                pbDocker=pbDocker,
                nGPU=nGPU,
                gpuModel=gpuModel,
                gpuDriverVersion=gpuDriverVersion,
                nThreads=nThreads,
                gbRAM=gbRAM,
                diskGB=diskGB,
                runtimeMinutes=runtimeMinutes,
                hpcQueue=hpcQueue,
                maxPreemptAttempts=maxPreemptAttempts
        }
    }

    File? to_compress_VCF = if doPON then select_first([mutect2_postpon.outputVCF]) else pb_mutect2_withoutPON.outputVCF


    call compressAndIndexVCF {
        input:
            inputVCF=select_first([to_compress_VCF])
    }

    output {
        File outputVCF = compressAndIndexVCF.outputVCF
        File outputTBI = compressAndIndexVCF.outputTBI
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
