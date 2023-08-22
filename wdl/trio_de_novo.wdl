version 1.0
# Copyright 2021 NVIDIA CORPORATION & AFFILIATES

task strelka {
    ## TODO: replace with CPU strelka
    input {
        File inputBAM
        File inputBAI
        File inputRefTarball
        String pbPATH
        File? pbLicenseBin

        String pbDocker  = "parabricks/3.7.0-1"
        Int maxPreemptAttempts = 3
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 500
        Int runtimeMinutes = 600
        String hpcQueue = "norm"
    }

    String outbase = basename(inputBAM, ".bam")
    String ref = basename(inputRefTarball, ".tar")

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputBAM, "GB")) + ceil(size(inputRefTarball, "GB")) + ceil(size(inputBAI, "GB")) + 50 else diskGB

    command <<<
        time tar xvf ~{inputRefTarball} && \
        touch ~{inputBAI} && \
        time ~{pbPATH} strelka \
        --in-bams ~{inputBAM} \
        --ref ~{ref} \
        --out-prefix ~{outbase}.strelka \
        --num-threads ~{nThreads} \
        ~{"--license-file " + pbLicenseBin} && \
        cp ~{outbase}.strelka.strelka_work/results/variants/variants.vcf.gz ~{outbase}.strelka.variants.vcf.gz && \
        cp ~{outbase}.strelka.strelka_work/results/variants/variants.vcf.gz.tbi ~{outbase}.strelka.variants.vcf.gz.tbi && \
        cp ~{outbase}.strelka.strelka_work/results/variants/genome.S1.vcf.gz ~{outbase}.strelka.genomic.vcf.gz && \
        cp ~{outbase}.strelka.strelka_work/results/variants/genome.S1.vcf.gz.tbi ~{outbase}.strelka.genomic.vcf.gz.tbi
    >>>

    output {
        File strelkaVCF = "~{outbase}.strelka.variants.vcf.gz"
        File strelkaTBI = "~{outbase}.strelka.variants.vcf.gz.tbi"
        File strelkaGenomicVCF = "~{outbase}.strelka.genomic.vcf.gz"
        File strelkaGenomicTBI = "~{outbase}.strelka.genomic.vcf.gz.tbi"
    }

    runtime {
        docker : "~{pbDocker}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : nThreads
        memory : "~{gbRAM} GB"
        hpcMemory : gbRAM
        hpcQueue : "~{hpcQueue}"
        hpcRuntimeMinutes : runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : maxPreemptAttempts
    }
}

task haplotypecaller {
    input {
        File inputBAM
        File inputBAI
        File inputRecal
        File inputRefTarball
        String pbPATH
        File? pbLicenseBin
        Boolean gvcfMode = false
        String? haplotypecallerPassthroughOptions

        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.1.0-1"
        Int maxPreemptAttempts = 3
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-t4"
        String gpuDriverVersion = "460.73.01"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
    }

    String outbase = basename(inputBAM, ".bam")
    String ref = basename(inputRefTarball, ".tar")

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputBAM, "GB")) + ceil(size(inputRefTarball, "GB")) + ceil(size(inputBAI, "GB")) + 65 else diskGB

    String outVCF = outbase + ".haplotypecaller" + (if gvcfMode then '.g' else '') + ".vcf"

    command <<<
        time tar xvf ~{inputRefTarball} && \
        time ~{pbPATH} haplotypecaller \
        ~{if gvcfMode then "--gvcf " else ""} \
        --in-bam ~{inputBAM} \
        --ref ~{ref} \
        --in-recal-file ~{inputRecal} \
        --out-variants ~{outVCF} \
        ~{"--license-file " + pbLicenseBin} && \
        bgzip -@ ~{nThreads} ~{outVCF} && \
        tabix ~{outVCF}.gz
    >>>

    output {
        File haplotypecallerVCF = "~{outVCF}.gz"
        File haplotypecallerTBI = "~{outVCF}.gz.tbi"
    }

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
}

task deepvariant {
    input {
        File inputBAM
        File inputBAI
        File inputRefTarball
        String pbPATH
        File? pbLicenseBin
        Boolean gvcfMode = false

        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.1.0-1"
        Int maxPreemptAttempts = 3
        Int nGPU = 4
        String gpuModel = "nvidia-tesla-t4"
        String gpuDriverVersion = "460.73.01"
        Int nThreads = 32
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 600
        String hpcQueue = "gpu"
    }

    String ref = basename(inputRefTarball, ".tar")
    String outbase = basename(inputBAM, ".bam")

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputBAM, "GB")) + ceil(size(inputRefTarball, "GB")) + ceil(size(inputBAI, "GB")) + 65 else diskGB

    String outVCF = outbase + ".deepvariant" + (if gvcfMode then '.g' else '') + ".vcf"

    command <<<
        time tar xf ~{inputRefTarball} && \
        time ~{pbPATH} deepvariant \
        ~{if gvcfMode then "--gvcf " else ""} \
        --ref ~{ref} \
        --in-bam ~{inputBAM} \
        --out-variants ~{outVCF} \
        ~{"--license-file " + pbLicenseBin} && \
        bgzip -@ ~{nThreads} ~{outVCF} && \
        tabix ~{outVCF}.gz
    >>>

    output {
        File deepvariantVCF = "~{outVCF}.gz"
        File deepvariantTBI = "~{outVCF}.gz.tbi"
    }

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
}

task restrictVCFToSample {
    input {
        File inputVCF
        File inputTBI
        String sample
        String bcftoolsPath = "bcftools"

        String bcftoolsDocker = "parabricks/3.7.0-1"
        Int maxPreemptAttempts = 3
        Int nThreads = 4
        Int gbRAM = 16
        Int diskGB = 0
        Int runtimeMinutes = 120
        String hpcQueue = "norm"
    }

    String outbase = basename(basename(inputVCF, ".gz"), ".vcf")

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputVCF, "GB") * 2.5) + 65 else diskGB

    command <<<
        ~{bcftoolsPath} view --threads ~{nThreads} -O z -o ~{outbase}.~{sample}.vcf.gz -s ~{sample} ~{inputVCF} && \
        tabix ~{outbase}.~{sample}.vcf.gz
    >>>

    output {
        File sampleVCF = "~{outbase}.~{sample}.vcf.gz"
        File sampleTBI = "~{outbase}.~{sample}.vcf.gz.tbi"
    }

    runtime {
        docker : "~{bcftoolsDocker}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : nThreads
        memory : "~{gbRAM} GB"
        hpcMemory : gbRAM
        hpcQueue : "~{hpcQueue}"
        hpcRuntimeMinutes : runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : maxPreemptAttempts
    }
}

task replaceVCFSampleName{
    input {
        File inputVCF
        File inputTBI
        String newName = ""
        String bcftoolsPath = "bcftools"

        String bcftoolsDocker = "parabricks/3.7.0-1"
        Int maxPreemptAttempts = 3
        Int nThreads = 3
        Int gbRAM = 15
        Int diskGB = 0
        Int runtimeMinutes = 60
        String hpcQueue = "norm"
    }

    String outbase = basename(basename(inputVCF, ".gz"), ".vcf")
    Array[String] samp_array = [newName]

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputVCF, "GB") * 2.5) + 50 else diskGB

    command <<<
        if [ -z "~{newName}" ]
        then
            mv ~{inputVCF} ~{outbase}.sample.vcf.gz && \
            mv ~{inputTBI} ~{outbase}.sample.vcf.gz.tbi
        else
            ~{bcftoolsPath} reheader \
            -s ~{write_lines(samp_array)} \
            -o ~{outbase}.sample.vcf.gz \
            ~{inputVCF} && \
            tabix ~{outbase}.sample.vcf.gz
        fi
    >>>

    output {
        File resampledVCF = "~{outbase}.sample.vcf.gz"
        File resampledTBI = "~{outbase}.sample.vcf.gz.tbi"
    }

    runtime {
        docker : "~{bcftoolsDocker}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : nThreads
        memory : "~{gbRAM} GB"
        hpcMemory : gbRAM
        hpcQueue : "~{hpcQueue}"
        hpcRuntimeMinutes : runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : maxPreemptAttempts
    }
}

task GLNexusJointGenotypeTrioGVCFs {
    input {
        File inputChildVCF
        File inputChildTBI
        File inputMotherVCF
        File inputMotherTBI
        File inputFatherVCF
        File inputFatherTBI
        String config
        String pbPATH
        File? pbLicenseBin

        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.1.0-1"
        Int maxPreemptAttempts = 3
        Int nThreads = 12
        Int gbRAM = 120
        Int diskGB = 0
        Int runtimeMinutes = 240
        String hpcQueue = "norm"
    }

    String childBase = basename(basename(basename(inputChildVCF, ".gz"), ".vcf"), ".pb.realn")
    String motherBase = basename(basename(basename(inputMotherVCF, ".gz"), ".vcf"), ".pb.realn")
    String fatherBase = basename(basename(basename(inputFatherVCF, ".gz"), ".vcf"), ".pb.realn")

    String outbase = childBase + "." + motherBase + "." + fatherBase + ".glnexus_" + config

    ## Use two decompression (bcftools view) threads
    Int viewThreads = 2
    ## Split threads used for compression and decompression, and save 
    ## one thread for OS operations
    Int compressThreads = nThreads - viewThreads - 1
    Int m_compressThreads = if compressThreads > 1 then compressThreads else 1
    ## Use all but two threads when running glNexus
    Int glnexusThreads = nThreads - 2
    Int m_glnexusThreads = if glnexusThreads > 1 then glnexusThreads else 1
    ## Reserve 12GB of RAM for OS operations.
    Int glnexusRAM = gbRAM - 12

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputChildVCF, "GB")) + ceil(size(inputMotherVCF, "GB")) + ceil(size(inputFatherVCF, "GB")) + 65 else diskGB

    command <<<
        ~{pbPATH} glnexus \
        ~{"--license-file " + pbLicenseBin} \
        --glnexus-options="--config ~{config} --mem-gbytes ~{glnexusRAM} --threads ~{m_glnexusThreads}" \
        --in-gvcf ~{inputChildVCF} \
        --in-gvcf ~{inputMotherVCF} \
        --in-gvcf ~{inputFatherVCF} \
        --out-bcf ~{outbase}.bcf && \
        bcftools view --threads ~{viewThreads} ~{outbase}.bcf | \
        bgzip -@ ~{m_compressThreads} -c > ~{outbase}.vcf.gz && \
        tabix ~{outbase}.vcf.gz
    >>>

    output {
        File outputVCF = "~{outbase}.vcf.gz"
        File outputTBI = "~{outbase}.vcf.gz.tbi"
    }

    runtime {
        docker : "~{pbDocker}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : nThreads
        memory : "~{gbRAM} GB"
        hpcMemory : gbRAM
        hpcQueue : "~{hpcQueue}"
        hpcRuntimeMinutes : runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : maxPreemptAttempts
    }
}

task numberOfCallersFilter {
    input {
        String sampleName
        File deepvariantVCF
        File haplotypecallerVCF
        File strelkaVCF
        File deepvariantTBI
        File haplotypecallerTBI
        File strelkaTBI
        String pbPATH
        File? pbLicenseBin
        Int minVotes = 3

        String pbDocker = "nvcr.io/nvidia/clara/clara-parabricks:4.1.0-1"
        Int maxPreemptAttempts = 3
        Int nThreads = 4
        Int gbRAM = 15
        Int diskGB = 0
        Int runtimeMinutes = 100
        String hpcQueue = "norm"
    }

    Int auto_diskGB = if diskGB == 0 then ceil(size(deepvariantVCF, "GB")) + ceil(size(haplotypecallerVCF, "GB")) + ceil(size(strelkaVCF, "GB")) + 65 else diskGB

    command <<<
        ~{pbPATH} votebasedvcfmerger \
        ~{"--license-file " + pbLicenseBin} \
        --min-votes ~{minVotes} \
        --in-vcf deepvariant:~{deepvariantVCF} \
        --in-vcf haplotypecaller:~{haplotypecallerVCF} \
        --in-vcf strelka2:~{strelkaVCF} \
        --out-dir "$(pwd)"/~{sampleName}.vbvm && \
        mv ~{sampleName}.vbvm/filteredVCF.vcf ~{sampleName}.intersection.vcf && \
        mv ~{sampleName}.vbvm/unionVCF.vcf ~{sampleName}.union.vcf &&
        bgzip ~{sampleName}.intersection.vcf && \
        tabix ~{sampleName}.intersection.vcf.gz && \
        bgzip ~{sampleName}.union.vcf && \
        tabix ~{sampleName}.union.vcf.gz
    >>>

    runtime {
        docker : "~{pbDocker}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : nThreads
        memory : "~{gbRAM} GB"
        hpcMemory : gbRAM
        hpcQueue : "~{hpcQueue}"
        hpcRuntimeMinutes : runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : maxPreemptAttempts
    }

    output {
        File intersectionVCF = "~{sampleName}.intersection.vcf.gz"
        File intersectionTBI = "~{sampleName}.intersection.vcf.gz.tbi"
        File unionVCF = "~{sampleName}.union.vcf.gz"
        File unionTBI = " ~{sampleName}.union.vcf.gz.tbi"
    }
}

task deNovoFilterNaive {
    input {
        File inputTrioVCF
        File inputTrioTBI
        String childSampleName
        String motherSampleName
        String fatherSampleName
        String filterScriptPath

        String dnmFilterScriptDocker = "parabricks/3.7.0-1"
        Int maxPreemptAttempts = 3
        Int nThreads = 3
        Int gbRAM = 14
        Int diskGB = 0
        Int runtimeMinutes = 100
        String hpcQueue = "norm"
    }

    String vcfName = basename(inputTrioVCF, ".gz")
    String outbase = basename(basename(inputTrioVCF, ".gz"), ".vcf")

    Int auto_diskGB = if diskGB == 0 then ceil(size(inputTrioVCF, "GB") * 3.2) + 65 else diskGB

    command <<<
        bgzip -c -d -@ ~{nThreads} ~{inputTrioVCF} > ~{vcfName} && \
        python ~{filterScriptPath} \
        --child ~{childSampleName} \
        --mother ~{motherSampleName} \
        --father ~{fatherSampleName} \
        -i ~{vcfName} \
        -o ~{outbase}.putative_dnms.vcf && \
        bgzip -@ ~{nThreads} ~{outbase}.putative_dnms.vcf && \
        tabix ~{outbase}.putative_dnms.vcf.gz
    >>>

    output {
        File dnmVCF = "~{outbase}.putative_dnms.vcf.gz"
        File dnmTBI = "~{outbase}.putative_dnms.vcf.gz.tbi"
    }

    runtime {
        docker : "~{dnmFilterScriptDocker}"
        disks : "local-disk ~{auto_diskGB} SSD"
        cpu : nThreads
        memory : "~{gbRAM} GB"
        hpcMemory : gbRAM
        hpcQueue : "~{hpcQueue}"
        hpcRuntimeMinutes : runtimeMinutes
        zones : ["us-central1-a", "us-central1-b", "us-central1-c"]
        preemptible : maxPreemptAttempts
    }
}

workflow ClaraParabricks_TrioDeNovo {
    input {
        ## Child inputs
        File inputChildBAM
        File inputChildBAI
        File inputChildBQSR
        String childSampleName

        ## Mother inputs
        File inputMotherBAM
        File inputMotherBAI
        File inputMotherBQSR
        String motherSampleName

        ## Father inputs
        File inputFatherBAM
        File inputFatherBAI
        File inputFatherBQSR
        String fatherSampleName

        ## Reference files in a tarball
        File refTarball

        ## A path to a valid Parabricks license file,
        ## which must be on the same file system as the inputs.
        File? pbLicenseBin
        String pbPath
        String tmpDir = "tmp_dir"

        ## An absolute path to a bcftools installation
        String bcftoolsPath = "bcftools"

        ## The path to the DNM filtering script.
        String dnmFilterPythonScriptPath

        ## DeepVariant Runtime Args
        Int nGPU_DeepVariant = 4
        String gpuModel_DeepVariant = "nvidia-tesla-v100"
        String gpuDriverVersion_DeepVariant = "460.73.01"
        Int nThreads_DeepVariant = 32
        Int gbRAM_DeepVariant = 120
        Int diskGB_DeepVariant = 0
        Int runtimeMinutes_DeepVariant = 600
        String hpcQueue_DeepVariant = "gpu"

        ## HaplotypeCaller Runtime Args
        Int nGPU_HaplotypeCaller = 4
        String gpuModel_HaplotypeCaller = "nvidia-tesla-v100"
        String gpuDriverVersion_HaplotypeCaller = "460.73.01"
        Int nThreads_HaplotypeCaller = 32
        Int gbRAM_HaplotypeCaller = 120
        Int diskGB_HaplotypeCaller = 0
        Int runtimeMinutes_HaplotypeCaller = 600
        String hpcQueue_HaplotypeCaller = "gpu"

        ## Strelka Runtime Args
        Int nThreads_Strelka = 32
        Int gbRAM_Strelka = 120
        Int diskGB_Strelka = 0
        Int runtimeMinutes_Strelka = 600
        String hpcQueue_Strelka = "norm"

        ## GLNexus settings
        Int nThreads_GLNexus_DeepVariant = 12
        Int nThreads_GLNexus_HaplotypeCaller = 12
        Int gbRAM_GLNexus_DeepVariant = 90
        Int gbRAM_GLNexus_HaplotypeCaller = 120
        String hpcQueue_GLNexus = "norm"
        Int runtimeMinutes_GLNexus = 240
        Int diskGB_GLNexus = 0

        ## Vote based VCF merger (ensemble filter) settings
        Int ensembleVotesMinimum = 3
    }

    ## Run strelka2 on the Child, Mother, and Father samples.
    call strelka as STRELKA_CHILD{
        input:
            inputBAM=inputChildBAM,
            inputBAI=inputChildBAI,
            inputRefTarball=refTarball,
            pbPATH=pbPath,
            pbLicenseBin=pbLicenseBin,
            nThreads=nThreads_Strelka,
            gbRAM=gbRAM_Strelka,
            diskGB=diskGB_Strelka,
            hpcQueue=hpcQueue_Strelka,
            runtimeMinutes=runtimeMinutes_Strelka
    }
    call strelka as STRELKA_MOTHER{
        input:
            inputBAM=inputMotherBAM,
            inputBAI=inputMotherBAI,
            inputRefTarball=refTarball,
            pbPATH=pbPath,
            pbLicenseBin=pbLicenseBin,
            nThreads=nThreads_Strelka,
            gbRAM=gbRAM_Strelka,
            diskGB=diskGB_Strelka,
            hpcQueue=hpcQueue_Strelka,
            runtimeMinutes=runtimeMinutes_Strelka
    }
    call strelka as STRELKA_FATHER{
        input:
            inputBAM=inputFatherBAM,
            inputBAI=inputFatherBAI,
            inputRefTarball=refTarball,
            pbPATH=pbPath,
            pbLicenseBin=pbLicenseBin,
            nThreads=nThreads_Strelka,
            gbRAM=gbRAM_Strelka,
            diskGB=diskGB_Strelka,
            hpcQueue=hpcQueue_Strelka,
            runtimeMinutes=runtimeMinutes_Strelka
    }

    ## Run HaplotypeCaller on the Child, Mother, and Father samples.
    call haplotypecaller as HC_CHILD{
        input:
            inputBAM=inputChildBAM,
            inputBAI=inputChildBAI,
            inputRecal=inputChildBQSR,
            inputRefTarball=refTarball,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPath,
            gvcfMode=true,
            nThreads=nThreads_HaplotypeCaller,
            nGPU=nGPU_HaplotypeCaller,
            gpuModel=gpuModel_HaplotypeCaller,
            gbRAM=gbRAM_HaplotypeCaller,
            diskGB=diskGB_HaplotypeCaller,
            hpcQueue=hpcQueue_HaplotypeCaller,
            runtimeMinutes=runtimeMinutes_HaplotypeCaller
    }
    call haplotypecaller as HC_MOTHER{
        input:
            inputBAM=inputMotherBAM,
            inputBAI=inputMotherBAI,
            inputRecal=inputMotherBQSR,
            inputRefTarball=refTarball,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPath,
            gvcfMode=true,
            nThreads=nThreads_HaplotypeCaller,
            nGPU=nGPU_HaplotypeCaller,
            gpuModel=gpuModel_HaplotypeCaller,
            gbRAM=gbRAM_HaplotypeCaller,
            diskGB=diskGB_HaplotypeCaller,
            hpcQueue=hpcQueue_HaplotypeCaller,
            runtimeMinutes=runtimeMinutes_HaplotypeCaller
    }
    call haplotypecaller as HC_FATHER{
        input:
            inputBAM=inputFatherBAM,
            inputBAI=inputFatherBAI,
            inputRecal=inputFatherBQSR,
            inputRefTarball=refTarball,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPath,
            gvcfMode=true,
            nThreads=nThreads_HaplotypeCaller,
            nGPU=nGPU_HaplotypeCaller,
            gpuModel=gpuModel_HaplotypeCaller,
            gbRAM=gbRAM_HaplotypeCaller,
            diskGB=diskGB_HaplotypeCaller,
            hpcQueue=hpcQueue_HaplotypeCaller,
            runtimeMinutes=runtimeMinutes_HaplotypeCaller
    }

    ## Fix haplotypecaller sample names in VCFs
    call replaceVCFSampleName as hcSampleFix_CHILD{
        input:
            inputVCF=HC_CHILD.haplotypecallerVCF,
            inputTBI=HC_CHILD.haplotypecallerTBI,
            newName=childSampleName,
            bcftoolsPath=bcftoolsPath
    }
    call replaceVCFSampleName as hcSampleFix_MOTHER{
        input:
            inputVCF=HC_MOTHER.haplotypecallerVCF,
            inputTBI=HC_MOTHER.haplotypecallerTBI,
            newName=motherSampleName,
            bcftoolsPath=bcftoolsPath
    }
    call replaceVCFSampleName as hcSampleFix_FATHER{
        input:
            inputVCF=HC_FATHER.haplotypecallerVCF,
            inputTBI=HC_FATHER.haplotypecallerTBI,
            newName=fatherSampleName,
            bcftoolsPath=bcftoolsPath
    }

    ## Run DeepVariant on the Child, Mother, and Father samples.
    call deepvariant as CHILD_DV{
        input:
            inputBAM=inputChildBAM,
            inputBAI=inputChildBAI,
            inputRefTarball=refTarball,
            gvcfMode=true,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPath,
            nThreads=nThreads_DeepVariant,
            nGPU=nGPU_DeepVariant,
            gpuModel=gpuModel_DeepVariant,
            gbRAM=gbRAM_DeepVariant,
            diskGB=diskGB_DeepVariant,
            hpcQueue=hpcQueue_DeepVariant,
            runtimeMinutes=runtimeMinutes_DeepVariant
    }
    call deepvariant as MOTHER_DV{
        input:
            inputBAM=inputMotherBAM,
            inputBAI=inputMotherBAI,
            inputRefTarball=refTarball,
            gvcfMode=true,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPath,
            nThreads=nThreads_DeepVariant,
            nGPU=nGPU_DeepVariant,
            gpuModel=gpuModel_DeepVariant,
            gbRAM=gbRAM_DeepVariant,
            diskGB=diskGB_DeepVariant,
            hpcQueue=hpcQueue_DeepVariant,
            runtimeMinutes=runtimeMinutes_DeepVariant
    }
    call deepvariant as FATHER_DV{
        input:
            inputBAM=inputFatherBAM,
            inputBAI=inputFatherBAI,
            inputRefTarball=refTarball,
            gvcfMode=true,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPath,
            nThreads=nThreads_DeepVariant,
            nGPU=nGPU_DeepVariant,
            gpuModel=gpuModel_DeepVariant,
            gbRAM=gbRAM_DeepVariant,
            diskGB=diskGB_DeepVariant,
            hpcQueue=hpcQueue_DeepVariant,
            runtimeMinutes=runtimeMinutes_DeepVariant
    }

    ## Fix sample names for mother / father / child
    call replaceVCFSampleName as dvSampleFix_CHILD{
        input:
            inputVCF=CHILD_DV.deepvariantVCF,
            inputTBI=CHILD_DV.deepvariantTBI,
            newName=childSampleName,
            bcftoolsPath=bcftoolsPath
    }
    call replaceVCFSampleName as dvSampleFix_MOTHER{
        input:
            inputVCF=MOTHER_DV.deepvariantVCF,
            inputTBI=MOTHER_DV.deepvariantTBI,
            newName=motherSampleName,
            bcftoolsPath=bcftoolsPath
    }
    call replaceVCFSampleName as dvSampleFix_FATHER{
        input:
            inputVCF=FATHER_DV.deepvariantVCF,
            inputTBI=FATHER_DV.deepvariantTBI,
            newName=fatherSampleName,
            bcftoolsPath=bcftoolsPath
    }

    ## Run glNexus on DV trio gVCFs
    call GLNexusJointGenotypeTrioGVCFs as glnexus_DV{
        input:
            inputChildVCF=dvSampleFix_CHILD.resampledVCF,
            inputChildTBI=dvSampleFix_CHILD.resampledTBI,
            inputFatherVCF=dvSampleFix_FATHER.resampledVCF,
            inputFatherTBI=dvSampleFix_FATHER.resampledTBI,
            inputMotherVCF=dvSampleFix_MOTHER.resampledVCF,
            inputMotherTBI=dvSampleFix_MOTHER.resampledTBI,
            config="DeepVariant",
            pbPATH=pbPath,
            pbLicenseBin=pbLicenseBin,
            nThreads=nThreads_GLNexus_DeepVariant,
            gbRAM=gbRAM_GLNexus_DeepVariant,
            runtimeMinutes=runtimeMinutes_GLNexus,
            diskGB=diskGB_GLNexus,
            hpcQueue=hpcQueue_GLNexus
    }

    ## De novo filter DV trio gVCF
    call deNovoFilterNaive as dnm_filter_DV {
        input:
            inputTrioVCF=glnexus_DV.outputVCF,
            inputTrioTBI=glnexus_DV.outputTBI,
            childSampleName=childSampleName,
            motherSampleName=motherSampleName,
            fatherSampleName=fatherSampleName,
            filterScriptPath=dnmFilterPythonScriptPath
    }

    ## Drop parental samples from DV trio gVCF
    call restrictVCFToSample as keepSample_DV{
        input:
            inputVCF=dnm_filter_DV.dnmVCF,
            inputTBI=dnm_filter_DV.dnmTBI,
            sample=childSampleName
    }

    ## Run glNexus on HC trio gVCFs
    call GLNexusJointGenotypeTrioGVCFs as glnexus_HC{
        input:
            inputChildVCF=hcSampleFix_CHILD.resampledVCF,
            inputChildTBI=hcSampleFix_CHILD.resampledTBI,
            inputFatherVCF=hcSampleFix_FATHER.resampledVCF,
            inputFatherTBI=hcSampleFix_FATHER.resampledTBI,
            inputMotherVCF=hcSampleFix_MOTHER.resampledVCF,
            inputMotherTBI=hcSampleFix_MOTHER.resampledTBI,
            config="gatk",
            nThreads=nThreads_GLNexus_HaplotypeCaller,
            pbPATH=pbPath,
            pbLicenseBin=pbLicenseBin,
            gbRAM=gbRAM_GLNexus_HaplotypeCaller,
            runtimeMinutes=runtimeMinutes_GLNexus,
            diskGB=diskGB_GLNexus,
            hpcQueue=hpcQueue_GLNexus
    }

    ## de novo filter HaplotypeCaller-glnexus gVCF
    call deNovoFilterNaive as dnm_filter_HC {
        input:
            inputTrioVCF=glnexus_HC.outputVCF,
            inputTrioTBI=glnexus_HC.outputTBI,
            filterScriptPath=dnmFilterPythonScriptPath,
            childSampleName=childSampleName,
            motherSampleName=motherSampleName,
            fatherSampleName=fatherSampleName
    }

    ## Keep only the child sample from the putative HC DNMs
    call restrictVCFToSample as keepSample_HC{
        input:
            inputVCF=dnm_filter_HC.dnmVCF,
            inputTBI=dnm_filter_HC.dnmTBI,
            sample=childSampleName
    }

    ## Use an ensemble filter to generate the union and intersection
    ## of the trio calls from DeepVariant and HaplotypeCaller and
    ## the germline Strelka2 calls of the child.
    call numberOfCallersFilter as vbvm_Child{
        input:
            sampleName=childSampleName,
            deepvariantVCF=keepSample_DV.sampleVCF,
            deepvariantTBI=keepSample_DV.sampleTBI,
            haplotypecallerVCF=keepSample_HC.sampleVCF,
            haplotypecallerTBI=keepSample_HC.sampleTBI,
            strelkaVCF=STRELKA_CHILD.strelkaVCF,
            strelkaTBI=STRELKA_CHILD.strelkaTBI,
            pbLicenseBin=pbLicenseBin,
            pbPATH=pbPath,
            minVotes=ensembleVotesMinimum
    }

    output {
        ## DNM + VBVM intersection
        File output_vbvm_intersection_vcf = vbvm_Child.intersectionVCF
        File output_vbvm_intersection_tbi = vbvm_Child.intersectionTBI

        ## DNM + VBVM union
        File output_vbvm_union_vcf = vbvm_Child.unionVCF
        File output_vbvm_union_tbi = vbvm_Child.unionTBI

        ## DeepVariant Trio VCF
        File glnexus_deepvariant_trio_vcf = glnexus_DV.outputVCF
        File glnexus_deepvariant_trio_TBI = glnexus_DV.outputTBI

        ## HaplotypeCaller Trio VCF
        File glnexus_haplotypecaller_trio_vcf = glnexus_HC.outputVCF
        File glnexus_haplotypecaller_trio_TBI = glnexus_HC.outputTBI

        ## Strelka Child VCF
        File child_strelka_vcf = STRELKA_CHILD.strelkaVCF
        File child_strelka_tbi = STRELKA_CHILD.strelkaTBI

        ## Strelka Mother VCF
        File mother_strelka_vcf = STRELKA_MOTHER.strelkaVCF
        File mother_strelka_tbi = STRELKA_MOTHER.strelkaTBI

        ## Strelka Father VCF
        File father_strelka_vcf = STRELKA_FATHER.strelkaVCF
        File father_strelka_tbi = STRELKA_FATHER.strelkaTBI
    }

    meta {
        Author: "Nvidia Clara Parabricks"
    }
}
