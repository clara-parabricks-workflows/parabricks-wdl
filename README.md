Parabricks WDL
-----------------------

# Introduction
This repository contains workflows for accelerated genomic analysis using Nvidia Clara Parabricks
written in the [Workflow Description Language (WDL)](https://github.com/openwdl/wdl). A WDL script is
composed of Tasks, which describe a single command and its associated inputs, runtime parameters, and
outputs; tasks can then be chained together via their inputs and outputs to create Workflows, which themselves
take a set of inputs and produce a set of outputs.

To learn more about Nvidia Clara Parabricks see [our page describing accelerated genomic analysis](https://www.nvidia.com/en-us/clara/genomics/).

# Available workflows
 - fq2bam : Align reads with Clara Parabricks' accelerated version of BWA mem.
 - bam2fq2bam: Extract FASTQ files from a BAM file and realign them to produce a new BAM file on a different reference.
 - germline_calling: Run accelerated GATK HaplotypeCaller and/or accelerated DeepVariant to produce germline VCF or gVCF files for a single sample.
 - somatic_calling: Run accelerated Mutect2 on a matched tumor-normal sample pair to generate a somatic VCF.
 - RNA: Run accelerated RNA-seq alignment using STAR.
 - trio_de_novo_calling: Run accelerated germline calling for a trio sample set before joint calling and filtering for putative de novo mutations.

# Getting Started
All pipelines in this repository have been validated using WOMtool and tested to run using Cromwell.

## Setting up your runtime environment
### Install a modern Java implementation
The current Cromwell releases require a modern (>= v1.10) Java implementation. We have tested Cromwell through version
80 on both Oracle Java and OpenJDK. For Ubuntu 20.04, the following command will install a sufficient Java runtime:

```bash
sudo apt install default-jdk
```

### Download Cromwell and WOMTool
Cromwell and WOMTool are available from [the Release page on Cromwell's GitHub](https://github.com/broadinstitute/cromwell/releases).

To download Cromwell and WOMTool, the following commands should work:

```bash
## Update the version as needed
export version=81
wget https://github.com/broadinstitute/cromwell/releases/download/${version}/cromwell-${version}.jar
https://github.com/broadinstitute/cromwell/releases/download/${version}/womtool-${version}.jar
```

## Download test data or bring your own
We recommend test data provided by Google Brain's Public Sequencing project. The HG002 FASTQ files
can be downloaded with the following commands:

```bash
wget https://storage.googleapis.com/brain-genomics-public/research/sequencing/fastq/hiseqx/wgs_pcr_free/30x/HG002.hiseqx.pcr-free.30x.R1.fastq.gz
wget https://storage.googleapis.com/brain-genomics-public/research/sequencing/fastq/hiseqx/wgs_pcr_free/30x/HG002.hiseqx.pcr-free.30x.R2.fastq.gz
```

## Run your first workflow
There are example JSON input slugs in the `example_inputs` directory. To run your first workflow, you can edit the minimal inputs file (`fq2bam.minimalInputs.json`). If you want
more advanced control over inputs or need additional ones you can modify the full inputs file (`fq2bam.fullInputs.json`).

Here is a valid minimal example that runs locally, assuming that your test data is inside the `parabricks-wdl` repo.

# Developing Parabricks-WDL

### Contributing new code
Please see CONTRIBUTING_WDL.md for more information about requirements for WDL contributions to this repo.

To validate your WDL, you can run `make validate`. To use a custom WOMtool (i.e., if womtool-82.jar is not in the local directory), you can run `make validate WOMTOOL=/path/to/womtool-<version>.jar`.


To set the parabricks docker container to the default:

```bash
make set_docker
```

to set it to a custom image:  

```bash
make set_docker PBDOCKER="<repo>/<image>[:<tag>]`
```

### Validating your WDL file
