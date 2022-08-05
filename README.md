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
 - create_pon: Generate a Panel-of-Normals file for use with accelerated Mutect2.
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
mkdir test_data
cd test_data
wget https://storage.googleapis.com/brain-genomics-public/research/sequencing/fastq/hiseqx/wgs_pcr_free/30x/HG002.hiseqx.pcr-free.30x.R1.fastq.gz
wget https://storage.googleapis.com/brain-genomics-public/research/sequencing/fastq/hiseqx/wgs_pcr_free/30x/HG002.hiseqx.pcr-free.30x.R2.fastq.gz
```


## Run your first workflow
There are example JSON input slugs in the `example_inputs` directory. To run your first workflow, you can edit the minimal inputs file (`fq2bam.minimalInputs.json`). If you want
more advanced control over inputs or need additional ones you can modify the full inputs file (`fq2bam.fullInputs.json`).


### Running locally using Parabricks installation
The following example will run the fq2bam command on a local machine with a Clara Parabricks installation at `/usr/bin/parabricks/`:

```bash
## Create the inputs file, removing optional inputs
java -jar ../womtool-81.jar inputs ../wdl/fq2bam.wdl | grep -v "optional" > inputs.local.json
```

Then, edit the inputs file to contain the proper values and remove any trailing commas:

```json
{
  "ClaraParabricks_fq2bam.inputFASTQ_2": "chr22.HG002.hiseqx.pcr-free.30x.R2.fastq.gz",
  "ClaraParabricks_fq2bam.pbLicenseBin": "/usr/bin/parabricks/license.bin",
  "ClaraParabricks_fq2bam.inputKnownSitesTBI": "chr22.Mills_1000G_known_indels.vcf.gz.tbi",
  "ClaraParabricks_fq2bam.inputRefTarball": "chr22.Homo_sapiens_assembly38.fasta.tar",
  "ClaraParabricks_fq2bam.inputKnownSites": "chr22.Mills_1000G_known_indels.vcf.gz",
  "ClaraParabricks_fq2bam.inputFASTQ_1": "chr22.HG002.hiseqx.pcr-free.30x.R1.fastq.gz",
  "ClaraParabricks_fq2bam.pbPATH": "/usr/bin/parabricks/pbrun"
}
```

To run using a local installation, we'll use the `local.wdl.conf` configuration, which
configures Cromwell to use a local Parabricks installation:

```bash
 java -Dconfig.file=../config_wdl/local.wdl.conf -jar ../cromwell-81.jar run -i inputs.local.json ../wdl/fq2bam.wdl 
```

### Running using Google Cloud Project

Next, we'll run the same workflow on Google Cloud There are a few major changes that need to be made to run a workflow on Google Cloud:

1. Copy inputs and license to a Google Cloud Storage (GCS) bucket
2. Edit the inputs to reflect the location of the inputs in GCS.
3. The inputs must contain a valid Docker image for Parabricks

The following commands should be sufficient assuming you have the Google Cloud SDK installed:

```bash
## Create a google bucket
gsutil mb test-project-bucket

## Copy inputs to the bucket
gsutil cp chr22.Homo_sapiens_assembly38.fasta.tar gs://test-project-bucket/
gsutil cp chr22.Mills_1000G_known_indels.vcf.gz gs://test-project-bucket/
gsutil cp chr22.Mills_1000G_known_indels.vcf.gz.tbi gs://test-project-bucket/
gsutil cp chr22.HG002.hiseqx.pcr-free.30x.R1.fastq.gz gs://test-project-bucket/
gsutil cp chr22.HG002.hiseqx.pcr-free.30x.R2.fastq.gz gs://test-project-bucket/

## Copy the parabricks license to the bucket
gsutil cp /usr/bin/parabricks/license.bin gs://test-project-bucket/
```

Next, update the inputs to reflect their position in GCS:

```json
{
  "ClaraParabricks_fq2bam.inputFASTQ_2": "gs://test-project-bucket/chr22.HG002.hiseqx.pcr-free.30x.R2.fastq.gz",
  "ClaraParabricks_fq2bam.pbLicenseBin": "gs://test-project-bucket/license.bin",
  "ClaraParabricks_fq2bam.inputKnownSitesTBI": "gs://test-project-bucket/chr22.Mills_1000G_known_indels.vcf.gz.tbi",
  "ClaraParabricks_fq2bam.inputRefTarball": "gs://test-project-bucket/chr22.Homo_sapiens_assembly38.fasta.tar",
  "ClaraParabricks_fq2bam.inputKnownSites": "gs://test-project-bucket/chr22.Mills_1000G_known_indels.vcf.gz",
  "ClaraParabricks_fq2bam.inputFASTQ_1": "gs://test-project-bucket/chr22.HG002.hiseqx.pcr-free.30x.R1.fastq.gz",
  "ClaraParabricks_fq2bam.pbPATH": "pbrun",
  "ClaraParabricks_fq2bam.pbDocker": "clara-parabricks/clara-parabricks-cloud:3.7.0"
}
```


# Build larger workflows and analyze your own data

This repository serves both as a set of pre-configured workflows and a set of building blocks for generating your own wokrflows incorporating Clara Parabricks. See 


# WDL Support

All workflows in this repository support [WDL version 1.0](https://github.com/openwdl/wdl/blob/main/versions/1.0/SPEC.md). Support for some WDL features varies by the backend used for a given run.

Support for WDL features:

- Call Caching: call caching is not tested on this repository, but should be functional. See the Cromwell docs for how to enable call caching.
- Automatic parallelization: WDL supports running tasks that are independent in the execution DAG in parallel. This feature is supported on the `gcp` and `slurm` backends. *This feature is disabled by default for the `local` and `localDocker` backends.* To enable this feature, modify the `maxForks` variable in the corresponding config file. Note: users should adjust thread counts for individual tools to ensure they do not oversubscribe their system when running with maxForks > 1.
- Imports: This repository supports GitHub-style imports of tasks / workflows. However, this feature is not supported by Nvidia and no guarantee of functionality or maintenance is provided. We recommend forking this repository and maintaining your own stable branch for imports should you desire to use this feature.
- Terra: All workflows in this repository will run on Terra. Search for Clara Parabricks on Terra for the latest version.
- Backends: While we only support the backends listed in `config/`, other backends may work with minimal adjustement. This compatibility is not guaranteed or tested unless otherwise noted.


# Developing Parabricks-WDL

## Contributing new code
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

You can validate all the WDLs in this repo's `wdl` directory by running `make validate`. To use a specific path to womtool, run `make validate WOMTOOL=/path/to/womtool-<version>.jar`.


