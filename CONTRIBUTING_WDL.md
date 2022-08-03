# Contribution Guidelines

# WDL Requirements

## WDL versions and style

1. All workflows should be declared `version 1.0` as the first line in the file and compatible
with the WDL version 1.0 syntax defined in the specification.

2. WDL variables should utilize the standard WDL tilde-based syntax rather than the `$` symbol. The
`$` should only be used for shell variables.

3. Every task should contain the following sections, even if they are empty:
  - input
  - command 
  - output 
  - runtime

4. `command` sections should use the standard `command { ... }` syntax and not the `<<< ... >>>` (heredoc) syntax.

### Tasks
1. Tasks should be named with short names using camelCase.

2. All WDL tasks containing a Parabricks command must include the following inputs in their `input` section:

```     
        File pbLicenseBin
        String pbPATH
        String pbDocker = "parabricks-cloud:latest"
        String tmpDir = "tmp_fq2bam"
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-v100"
        String gpuDriverVersion = "460.73.01"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
        Int maxPreemptAttempts = 3
```

3. The required inputs **with the exception of pbLicenseBin and pbPATH** should include sensible, consistent defaults. 

4. `pbPATH` and `pbLicenseBin` should **never** include a default and must always be specified explicitly.

5. Task inputs which are optional should use a default and be implcitly optional rather than explicitly so.

6. CPU-only tasks *may exclude* the `pbLicenseBin`, `pbPATH`, `nGPU`, `gpuModel`, and `gpuDriverVersion`, but
 **their runtime sections should be updated to remove any unpassed inputs.**

7. When called as part of a workflow, it is preferable to call tasks with a descriptive alias that includes the original task name (e.g., `call bam2fq as bam2fq_tumor`).
Aliasing is not strictly required where tasks are unambiguous (i.e., called only once). An alias should use underscore_spaces.

### Workflows

1. Workflow names should start with a capitalized letter and use CamelCase and underscore_spaces.

2. All Clara Parabricks workflows should begin with `ClaraParabricks`.

3. Workflows should be defined **at the bottom** of their WDL script after all their composite tasks have been defined.

4. Workflow inputs should closely mirror task inputs. If two tasks take different values for the same input and it must be specified at the workflow level,
the Workflow input should be suffixed with a descriptor for the task (e.g., `nGPUs_HaplotypeCaller` and `nGPUs_DeepVariant`).

### Imports

In general, usage of WDL imports should be minimzed. Any WDL imports should be restricted to global GitHub 
imports using a fixed commit hash OR 
top-of-tree `main` branch. Local filesystem imports should not be used as they are unstable across
systems.

## WDL runtime arguments

1. All WDL tasks should have the following runtime section to 
ensure compatability with the supported backends:

```wdl
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
```

# Testing and compatability

1. All WDL tasks and workflows should be tested against at least Cromwell 80.

2. All WDL tasks and workflows should be verified on the following four backends:
  - local Parabricks install
  - local Parabricks Docker container
  - Google Cloud Project
  - SLURM

# Example inputs

1. Two sets of example inputs should be generated for every workflow,
one containing only required (non-optional) inputs and another containing all inputs.

Inputs can be generated using the following command:

```bash
## for womtool version 82:

java -jar womtool-82.jar inputs <workflow file> > inputs.json.
```

**See the example_inputs directory for naming convention examples.**

# Configuration files

1. Configuration files should be placed in the `config` directory.

2. Configuration files should be descriptively named.

3. **Be careful not to leak secrets in configuration files.**