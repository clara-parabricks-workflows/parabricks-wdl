version 1.0

task mutect2_prepon {
    input {
        File ponVCF
        File ponTBI
        String pbPATH
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

    Int auto_diskGB = if diskGB == 0 then ceil(3.0 * size(ponVCF, "GB") * 2) + 50 else diskGB
    String localVCF = basename(ponVCF)
    String localTBI = basename(ponTBI)
    String outbase = basename(ponVCF, ".vcf.gz")
    command {
        cp ~{ponVCF} ~{localVCF} && \
        cp ~{ponTBI} ~{localTBI} && \
        time ~{pbPATH} prepon \
        --in-pon-file ~{localVCF} \
        ~{"--license-file " + pbLicenseBin}
    }
    output {
        File outputPON = "~{localVCF}.pon"
        File outputVCF = "~{localVCF}"
        File outputTBI = "~{localTBI}"
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

workflow ClaraParabricks_Somatic {
    input {
        File ponVCF
        File ponTBI
        String pbPATH
        File? pbLicenseBin
        String pbDocker = "gcr.io/clara-lifesci/parabricks-cloud:3.8.0-1"
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

    call mutect2_prepon {
        input: 
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

    output {
        File outputPON = mutect2_prepon.outputPON
        File outputVCF = mutect2_prepon.outputVCF
        File outputTBI = mutect2_prepon.outputTBI
    }
}