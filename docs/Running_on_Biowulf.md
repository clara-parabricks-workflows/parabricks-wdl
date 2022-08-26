# Running Clara Parabricks WDL on the NIH Biowulf System
Eric T. Dawson  
18 August 2022

## Overview
This document provides a basic getting started guide to running
the WDL workflows in this repository on the NIH Biowulf compute cluster.
Note that these instructions can change often and should not be considered stable.

## Preequisites: install Singularity and build a Biowulf-compatible Parabricks installation

### Install Singularity

### Pull the latest Parabricks container

```bash
git pull nvcr.io/nv-parabricks-dev/clara-parabricks:4.0.0-1.beta2
```

### Build a Parabricks Singularity / Apptainer package

```bash

```

## Getting started

### Clone the latest parabricks-WDL repository

```bash
git clone --resursive https://github.com/clara-parabricks-workflows/parabricks-wdl
```

### Set up input files

To run on Biowulf, we'll need to do the following:

1. Set the appropriate variables for runtime and compute resources in the workflow inputs (so that we request configs available on Biowulf).
2. Use the Biowulf Cromwell configuration

For this example, we're also going to use CromRunner to write our submission scripts for the cluster. While this isn't necessary,
it makes it easy to write batches in inputs in a declarative manner. The generated files can also be used as examples for your
own scripts.

#### Stage 1: FASTQ2BAM


We'll first set up and run Clara Parabricks fastq2bam to align reads, run BQSR, mark duplicates and sort alignments to produce
a sorted, indexed BAM file. 

The fq2bam workflow has already been written in WDL; to run on Biowulf, we just need to set up our inputs and use the `biowulf.wdl.conf` configuration file.

First, let's copy the example inputs file to a file named `inputs.fq2bam.template.json`:

```bash
cp parabricks-wdl/example_inputs/fq2bam.fullInputs.json inputs.fq2bam.template.json
```

We need to modify our input template to have tags, which are special indicator variables
that CromRunner can use for variable replacement. Tags are specified by placing a variable name in 
angle brackets (`<>`):

```json
{
  "ClaraParabricks_fq2bam.sampleName": "<SAMPLE_NAME>",
  "ClaraParabricks_fq2bam.fq2bam.hpcQueue": "gpu",
  "ClaraParabricks_fq2bam.inputKnownSitesVCF": "/path/to/knownSites.vcf.gz",
  "ClaraParabricks_fq2bam.inputFASTQ_2": "<INPUT_FASTQ_1>",
  "ClaraParabricks_fq2bam.inputFASTQ_2": "<INPUT_FASTQ_2>",
  "ClaraParabricks_fq2bam.runtimeMinutes": "600",
  "ClaraParabricks_fq2bam.tmpDir": "tmp_fq2bam",
  "ClaraParabricks_fq2bam.gbRAM": "120",
  "ClaraParabricks_fq2bam.readGroupName": "<READ_GROUP_NAME>",
  "ClaraParabricks_fq2bam.nGPU": "4",
  "ClaraParabricks_fq2bam.inputKnownSitesTBI": "/path/to/knownSites.vcf.gz.tbi",
  "ClaraParabricks_fq2bam.inputRefTarball": "/path/to/reference.fa.tar",
  "ClaraParabricks_fq2bam.gpuModel": "v100x",
  "ClaraParabricks_fq2bam.libraryName": "<LIBRARY_NAME>",
  "ClaraParabricks_fq2bam.inputFASTQ_1": "File",
  "ClaraParabricks_fq2bam.platformName": "ILMN",
  "ClaraParabricks_fq2bam.nThreads": "24",
  "ClaraParabricks_fq2bam.pbPATH": "/path/to/parabricks/pbrun",
  "ClaraParabricks_fq2bam.pbLicenseBin": "/path/to/parabricks/license.bin"
}
```

Next, we'll set up a CSV-formatted manifest file that contains the variables we need to replace
in out template inputs.

```csv
SAMPLE_NAME,INPUT_FASTQ_1,INPUT_FASTQ_2,READ_GROUP_NAME,LIBRARY_NAME
HG001,/path/to/hg001/HG001.hiseqx.pcr-free.30x.R1.fastq.gz,/path/to/hg001/HG001.hiseqx.pcr-free.30x.R2.fastq.gz,HG001,HG001_LIB
HG002,/path/to/hg002/HG002.hiseqx.pcr-free.30x.R1.fastq.gz,/path/to/hg002/HG002.hiseqx.pcr-free.30x.R2.fastq.gz,HG002,HG002_LIB
HG003,/path/to/hg003/HG003.hiseqx.pcr-free.30x.R1.fastq.gz,/path/to/hg003/HG003.hiseqx.pcr-free.30x.R2.fastq.gz,HG003,HG003_LIB
```

We need to move this file to Biowulf so we can use it with CromRunner:

```bash
scp manifest.csv $USER@biowulf.nih.gov:
scp inputs.fq2bam.template.json $USER@biowulf.nih.gov
```

Now, we can set up our run on Biowulf. Let's log in, organize our files in a directory,
load the modules we need, and use CromRunner to generate our input and launch files:

```bash
ssh $user@biowulf.nih.gov

## Install CromRunner if not already installed
git clone --recursive https://github.com/edawson/cromrunner.git

mkdir test_study
cd test_study

## Load the modules we need, which for now is just Cromwell, java, and python
module load python java cromwell

## Loading the cromwell module will fill our environment with the environment variable
## $CROMWELL_JAR, so we can access the latest version installed on Biowulf (without having to maintain our own)

## Move out input manifest and template here:
mv ../manifest.csv .
mv ../inputs.fq2bam.template.json .

## Now we can run CromRunner to generate our inputs, using our manifest, our template,
## our config, and our WDL.

python ../cromrunner/cromrunner.py \
  --cromwell-path $CROMWELL_JAR \
  --config ../parabricks-wdl/config/biowulf.wdl.conf \
  --wdl ../parabricks-wdl/wdl/fq2bam.wdl \
  --input-template inputs.fq2bam.template.json \
  --input-manifest manifest.csv \
  --delimiter ',' \
  --backend swarm \
  --modules singularity,python,java,cromwell,samtools \
  --prefix CromRunner_HG001-HG003-test
```

This should print:
```bash
Loaded 3 work units.
```

CromRunner will generate a directory (prefixed with `CromRunner_HG001-HG003-test` and ending in a random string of characters).
This directory will contain a number of files:

```bash
ls CromRunner_HG001-HG003-test-RTIDIEQH-KTCBWCXR-NXEQXYQM
```

```bash
BIUSDAFVTUIGVNBQ.inputs.json
CUAGTWIWQLMWYEGW.inputs.json
HMASRAKEMFICTRQU.inputs.json
swarm_submit.sh
swarm_tasks.txt
```

CromRunner has automatically written a [swarm file](https://hpc.nih.gov/apps/swarm.html#input) and a basic
SLURM submission script that will run the Cromwell server. The cromwell server will launch tasks in the workflow as
individual SLURM jobs. The server is set to run for up to three 
days by default *but will almost certainly finish before that time, depdening on the size of the job queue.*

To submit this job, run:

```bash
./CromRunner_HG001-HG003-test-RTIDIEQH-KTCBWCXR-NXEQXYQM/swarm_submit.sh
```

This will return the job ID. You can then check the status of the job(s) using `sjobs`, though this may take some time
to populate.

### Stage 2: Germline Calling

Once `fq2bam` is finished, we can run the germline_calling WDL to call variants with accelerated HaplotypeCaller and DeepVariant.


We will again need to prepare a template input JSON file. Let's copy the `example_inputs/germline_calling.fullInputs.json` file
to a new file called `germline_calling.template.json` and fill it with the following values:

```json
{
  "ClaraParabricks_Germline.inputRefTarball": "/path/to/reference.fa.tar",
  "ClaraParabricks_Germline.inputRecal": "<INPUT_RECAL>",
  "ClaraParabricks_Germline.gbRAM_DeepVariant": 120,
  "ClaraParabricks_Germline.nThreads_HaplotypeCaller": 24,
  "ClaraParabricks_Germline.pbLicenseBin": "/path/to/parabricks/license.bin",
  "ClaraParabricks_Germline.gbRAM_HaplotypeCaller": 130,
  "ClaraParabricks_Germline.nThreads_DeepVariant": 24,
  "ClaraParabricks_Germline.nGPU_DeepVariant": 3,
  "ClaraParabricks_Germline.pbPATH": "/path/to/parabricks/pbrun",
  "ClaraParabricks_Germline.nGPU_HaplotypeCaller": 3,
  "ClaraParabricks_Germline.hpcQueue_DeepVariant": "gpu",
  "ClaraParabricks_Germline.gpuModel_HaplotypeCaller": "p100",
  "ClaraParabricks_Germline.gpuModel_DeepVariant": "v100x",
  "ClaraParabricks_Germline.hpcQueue_HaplotypeCaller": "gpu",
  "ClaraParabricks_Germline.runtimeMinutes_DeepVariant": 600,
  "ClaraParabricks_Germline.inputBAI": "<INPUT_BAI>",
  "ClaraParabricks_Germline.inputBAM": "<INPUT_BAM>",
}
```

Note that there are many optional arguments; you can see all of these by looking at the `example_inputs/germline_calling.fullInputs.json` file. Two commonly used ones are `gvcfMode` and `haplotypecallerPassthroughOptions`. These can be specified by adding the following lines
to the JSON file:
```
  "ClaraParabricks_Germline.gvcfMode": true,
  "ClaraParabricks_Germline.haplotypecallerPassthroughOptions": "",
```

We're now ready to fill out a manifest and write our inputs and submission scripts. First, we need to find our BAM/BAI/BQSR files
which are present in the `cromwell-executions` directory:

```bash
ls -lrth cromwell-executions/*/ClaraParabricks_FQ2BAM/call-fq2bam/execution/
```

Once we have the paths of our BAMs, BAIs, and RECAL files, we can place them in a manifest. Let's write a manifest named `germline_calling.manifest.csv` with
the following contents:

```csv
SAMPLE_NAME,INPUT_BAM,INPUT_BAI,INPUT_BQSR
HG001,HG001.hiseqx.pcr-free.30x.R1.pb.bam,HG001.hiseqx.pcr-free.30x.R1.pb.bam.bai,HG001.hiseqx.pcr-free.30x.R1.pb.BQSR-REPORT.txt
HG002,HG002.hiseqx.pcr-free.30x.R1.pb.bam,HG002.hiseqx.pcr-free.30x.R1.pb.bam.bai,HG002.hiseqx.pcr-free.30x.R1.pb.BQSR-REPORT.txt
HG003,HG003.hiseqx.pcr-free.30x.R1.pb.bam,HG003.hiseqx.pcr-free.30x.R1.pb.bam.bai,HG003.hiseqx.pcr-free.30x.R1.pb.BQSR-REPORT.txt
```

We can run CromRunner again to generate our inputs and submit scripts. **Note the different WDL, template inputs, and manifest**:

```bash
python ../cromrunner/cromrunner.py \
  --cromwell-path $CROMWELL_JAR \
  --config ../parabricks-wdl/config/biowulf.wdl.conf \
  --wdl ../parabricks-wdl/wdl/germline_calling.wdl \
  --input-template germline_calling.template.json \
  --input-manifest germline_calling.manifest.csv \
  --delimiter ',' \
  --backend swarm \
  --modules singularity,python,java,cromwell,samtools \
  --prefix CromRunner-GermlineCalling
```

This will create a new CromRunner directory, prefixed with `CromRunner-Germlinecalling`, like so:

```
CromRunner-Germlinecalling-EWRTQQVV-TYRLJJOE-LOKPPAAM
```

Again, this directory will contain inputs and submission script. To launch or servers to manage subjobs, we can again run:

```bash
./CromRunner-Germlinecalling-EWRTQQVV-TYRLJJOE-LOKPPAAM/swarm_submit.sh
```


This will again launch three jobs and (eventually) several subjobs. When finished, these results will be in the `cromwell-executions` directory.

## Conclusion and getting help

For more help with Cromwell on Biowulf see the [User Guide](https://hpc.nih.gov/apps/cromwell.html).

For CromRunner, see the [CromRunner repsitory](https://github.com/edawson/cromrunner).

For parabricks-wdl, see the [Parabricks-WDL repository](https://github.com/clara-parabricks-workflows/parabricks-wdl.git). 