version 1.0

task index {
    input {
        File inputFASTA
        Int diskGB = 230
    }
    String outbase = basename(inputFASTA)
    command {
        samtools faidx ~{inputFASTA} && \
        bwa index ~{inputFASTA} && \
        tar cvf ~{outbase}.tar ~{inputFASTA}*
    }
    output {
        File refTarball = "~{outbase}.tar"
    }
    runtime {
        docker: "erictdawson/bwa"
        runtime_minutes : "180"
        cpu : "3"
        memory : "14 GB"
        diskGB : "~{diskGB}"
        disks: "local-disk ~{diskGB} SSD"
        queue : "norm"
        preemptible: 3
    }
}

workflow indexReference {
    input{
        File fastaFile
    }

    # Int diskGB = ceil(size(fastaFile, "GB"))
    Int diskGB = 200

    call index {
        input:
            inputFASTA=fastaFile,
            diskGB=diskGB
    }

    output {
        File refTarball = index.refTarball
    }
}