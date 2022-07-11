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

## Setting up your runtime environment
### Install a modern Java implementation
### Download Cromwell and WOMTool
## Download test data or bring your own
## Run your first workflow
## Accelerate your own workflow