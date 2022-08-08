version 1.0

task index {
    input {
        File inputFASTA
        String samtoolsPATH = "samtools"
        String bwaPATH = "bwa"
        String indexDocker = "clara-parabricks/bwa"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "norm"
    }
    String outbase = basename(inputFASTA)
    Int auto_diskGB = if diskGB == 0 then ceil(2.5* size(inputFASTA, "GB")) + 50 else diskGB

    command {
        ~{samtoolsPATH} faidx ~{inputFASTA} && \
        ~{bwaPATH} index ~{inputFASTA} && \
        tar cvf ~{outbase}.tar ~{inputFASTA}*
    }
    output {
        File refTarball = "~{outbase}.tar"
    }
    runtime {
        docker: "claraparabricks/bwa"
        runtime_minutes : "180"
        cpu : "3"
        memory : "14 GB"
        diskGB : "~{diskGB}"
        disks: "local-disk ~{diskGB} SSD"
        queue : "norm"
        preemptible: 3
    }
}
workflow ClaraParabricks_IndexReference {
    input{
        File fastaFile
        String samtoolsPATH = "samtools"
        String bwaPATH = "bwa"
        String indexDocker = "claraparabricks/bwa"
        Int nThreads = 32
        Int gbRAM = 120
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
            diskGB=diskGB,
    }

    output {
        File refTarball = index.refTarball
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
