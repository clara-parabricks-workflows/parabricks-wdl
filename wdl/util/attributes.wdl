version 1.0

struct RuntimeAttributes {
    Int diskGB
    Int nThreads
    Int gbRAM
    String hpcQueue
    Int runtimeMinutes
    Int maxPreemptAttempts
}

struct GPUAttributes {
    String gpuModel
    Int nGPU
    String? gpuDriver
}