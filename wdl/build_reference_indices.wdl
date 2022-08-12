version 1.0

task index {
    input {
        File inputFASTA
        String samtoolsPATH = "samtools"
        String bwaPATH = "bwa"
        String indexDocker = "clara-parabricks/bwa"
        Int nThreads = 4
        Int gbRAM = 48
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "norm"
        Int maxPreemptAttempts = 3
    }
    String outbase = basename(inputFASTA)
    String ref = basename(inputFASTA)
    Int auto_diskGB = if diskGB == 0 then ceil(4.0 * size(inputFASTA, "GB")) + 100 else diskGB

    command {
        ~{samtoolsPATH} faidx ~{ref} && \
        ~{bwaPATH} index ~{ref} && \
        tar cvf ~{outbase}.tar ~{ref}*
    }
    output {
        File refTarball = "~{outbase}.tar"
    }
    runtime {
        docker : "~{indexDocker}"
        disks : "local-disk ~{auto_diskGB} HDD"
        cpu : nThreads
        memory : "~{gbRAM} GB"
        hpcMemory : gbRAM
        hpcQueue : "~{hpcQueue}"
        hpcRuntimeMinutes : runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : maxPreemptAttempts
    }
}
workflow ClaraParabricks_IndexReference {
    input{
        File fastaFile
        String samtoolsPATH = "samtools"
        String bwaPATH = "bwa"
        String indexDocker = "claraparabricks/bwa"
        Int nThreads = 4
        Int gbRAM = 48
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "norm"
    }

    call index {
        input:
            inputFASTA=fastaFile,
            samtoolsPATH=samtoolsPATH,
            bwaPATH=bwaPATH,
            indexDocker=indexDocker,
            nThreads=nThreads,
            gbRAM=gbRAM,
            runtimeMinutes=runtimeMinutes,
            hpcQueue=hpcQueue,
            diskGB=diskGB
    }

    output {
        File refTarball = index.refTarball
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
