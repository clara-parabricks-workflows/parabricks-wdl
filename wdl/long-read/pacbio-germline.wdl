# Copyright 2021 NVIDIA CORPORATION & AFFILIATES
version 1.0

import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/util/attributes.wdl" as attributes
import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/long-read/minimap2.wdl" as mm2
import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/long-read/deepvariant.wdl" as dv

workflow ClaraParabricks_PacBio_Germline {
    input {
        File inputFASTQ
        File inputReference
        String sampleName

        Int diskGB = 0
        String pbmm2Docker = "erictdawson/pbmm2"
        Int gbRAM = 62
        String hpcQueue = "norm"
        Int runtimeMinutes = 240
        Int maxPreemptAttempts = 3
    }

    RuntimeAttributes mm2_runtime = {
            "diskGB": diskGB,
            "nThreads": nThreads,
            "gbRAM": gbRAM,
            "hpcQueue": hpcQueue,
            "runtimeMinutes": RuntimeAttributes,
            "maxPreemptAttempts": maxPreemptAttempts
    }

    call mm2.pbmm2 as minimap{
        input:
            inputFASTQ=inputFASTQ,
            inputReference=inputReference,
            sampleName=sampleName,
            runtime_attributes = mm2_runtime
    }

    call dv.deepvariant as deepvariant{
        input: 
            inputBAM=minimap.outputBAM,
            inputBAI=minimap.outputBAI,
            inputReference=inputReference
    }

    output {
        File outputVCF = deepvariant.deepvariantVCF
        File outputBAM = minimap.outputBAM
        File outputBAI = minimap.outputBAI
    }

}