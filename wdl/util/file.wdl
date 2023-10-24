version 1.0

import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/util/attributes.wdl" as attributes


## Return the size of a directory in Google Cloud Storage

task getDirectorySize {
    input {
        String dirPath
        String dockerImage = "google/cloud-sdk"
        RuntimeAttributes attributes = {
            "diskGB": 0,
            "nThreads": 4,
            "gbRAM": 11,
            "hpcQueue": "norm",
            "runtimeMinutes": 600,
            "maxPreemptAttempts": 3
        }

    }

    Int auto_diskGB = if (attributes.diskGB == 0) then 5 else attributes.diskGB

    command <<<
        set -e 
        # Authenticate with gcloud (assuming you've provided GOOGLE_APPLICATION_CREDENTIALS)
        gcloud auth activate-service-account --key-file=$(echo $GOOGLE_APPLICATION_CREDENTIALS)
        gsutil ls -l -r ~{dirPath} | tail -n 1 | grep -o "[0-9]* bytes" | cut -f 1 -d " " 
    >>>
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
    output {
        Int totalBytes = read_int(stdout())
    }
}
