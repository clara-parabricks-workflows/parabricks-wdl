version 1.0

import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/util/attributes.wdl" as attributes


## Merge a collection of BAM files into a single BAM file.
task mergeBAMs {
    input {
        Array[File] inputBAMs
        Array[File] inputBAIs
        String sampleName
        String dockerImage = "erictdawson/samtools"
        String readGroup_libraryName = "LIB1"
        String readGroup_ID = "RG1"
        String readGroup_platformName = "ILLUMINA"
        String readGroup_PU = "unit1"

        RuntimeAttributes attributes = {
            "diskGB": 0,
            "nThreads": 12,
            "gbRAM": 70,
            "hpcQueue": "norm",
            "runtimeMinutes": 600,
            "maxPreemptAttempts": 3
        }
    }
    Int auto_diskGB = if attributes.diskGB == 0 then ceil(size(inputBAMs, "GB") * 3.0) + 80 else attributes.diskGB

    String rgID = if sampleName == "SAMPLE" then readGroup_ID else sampleName + "-" + readGroup_ID
    command {
        set -e
        samtools merge -@ ~{attributes.nThreads - 1} -r "@RG\tID:~{rgID}\tLB:~{readGroup_libraryName}\tPL:~{readGroup_platformName}\tSM:~{sampleName}\tPU:~{readGroup_PU}" -o ~{sampleName}.merged.bam ~{sep = " " inputBAMs} && \
        samtools index ~{sampleName}.merged.bam
    }
    output {
        File mergedBAM = "~{sampleName}.merged.bam"
        File mergedBAI = "~{sampleName}.merged.bam.bai"
    }
    runtime {
        docker : "~{dockerImage}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : attributes.nThreads
        memory : "~{attributes.gbRAM} GB"
        hpcMemory : attributes.gbRAM
        hpcQueue : "~{attributes.hpcQueue}"
        hpcRuntimeMinutes : attributes.runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : attributes.maxPreemptAttempts
    }
}

## Return the sample(s) present within a BAM file
task getXAMSamples {
    input {
        File inputBAM
        File inputBAI
        String dockerImage

        RuntimeAttributes attributes = {
            "diskGB": 0,
            "nThreads": 12,
            "gbRAM": 70,
            "hpcQueue": "norm",
            "runtimeMinutes": 600,
            "maxPreemptAttempts": 3
        }
    }
    Int auto_diskGB = if attributes.diskGB == 0 then ceil(size(inputBAM, "GB") * 1.3) + 80 else attributes.diskGB

    command {
        samtools samples ~{inputBAM}
    }
    output {
        Int numSamples = ""
        Array[String] samples = ""
    }
    runtime {
        docker : "~{dockerImage}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : attributes.nThreads
        memory : "~{attributes.gbRAM} GB"
        hpcMemory : attributes.gbRAM
        hpcQueue : "~{attributes.hpcQueue}"
        hpcRuntimeMinutes : attributes.runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : attributes.maxPreemptAttempts
    }
}


task indexBAM {
    input {
        File inputBAM
        String dockerImage = "erictdawson/samtools"

        RuntimeAttributes attributes = {
            "diskGB": 0,
            "nThreads": 4,
            "gbRAM": 11,
            "hpcQueue": "norm",
            "runtimeMinutes": 600,
            "maxPreemptAttempts": 3
        }

    }
    Int auto_diskGB = if attributes.diskGB == 0 then ceil(size(inputBAM, "GB") * 1.3) + 80 else attributes.diskGB

    String outbase = basename(inputBAM)
    command {
        samtools index ~{"-@ " + attributes.nThreads} ~{inputBAM} ~{outbase}.bai
    }
    output {
        File outputBAI = "~{outbase}.bai"
    }
    runtime {
        docker : "~{dockerImage}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : attributes.nThreads
        memory : "~{attributes.gbRAM} GB"
        hpcMemory : attributes.gbRAM
        hpcQueue : "~{attributes.hpcQueue}"
        hpcRuntimeMinutes : attributes.runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : attributes.maxPreemptAttempts
    }
}