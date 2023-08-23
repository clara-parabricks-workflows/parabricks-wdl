# Copyright 2021 NVIDIA CORPORATION & AFFILIATES
version 1.0

import "https://raw.githubusercontent.com/clara-parabricks-workflows/parabricks-wdl/long-read/wdl/long-read/minimap2.wdl" as mm2


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

    call mm2.pbmm2 {
        input:
            inputFASTQ=inputFASTQ,
            inputReference=inputReference,
            sampleName=sampleName
    }
}