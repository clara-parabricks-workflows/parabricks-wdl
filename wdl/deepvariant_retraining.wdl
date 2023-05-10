task make_examples {
    input {
        File ref
        File bam
        File truth_vcf 
        File truth_bed 
        File examples 
        String region
    }

    String docker_image = "nvcr.io/nv-parabricks-dev/clara-parabricks-dvtrain:4.1.0-1.dvtrain"
    String binary_path = "/usr/local/parabricks/binaries/bin/deepvariant"
    String outbase = basename(bam, ".bam")

    command {
        ~{binary_path} \
        ~{ref} \
        ~{bam} \
        2 \
        -o ~{outbase}.vcf \
        -n 8 \
        --channel_insert_size \
        -L ~{region} \
        -disable-use-window-selector-model \
        --mode training \
        --truth_variants ~{truth_vcf} \
        --confident_regions ~{truth_bed} \
        --examples ~{examples} \
        -z 4
    }

    # TODO: The outputs are complicated, I'm not sure how to fit them here 
    output {

    }

    # TODO: Does docker_image need to be ~{docker_image}?
    # TODO: Are these the correct keywords for GPU type, and GPU count? 
    runtime {
        docker: "~{docker_image}"
        acceleratorType: "nvidia-tesla-t4"
        acceleratorCount: 4
        cpu: 48
        memory: "192GiB"
    }
}

task shuffle_data {
    input {
        String input_pattern_list
        String output_pattern_prefix
        String output_dataset_config
        String output_dataset_name
    }

    String shuffle_data_script_link = "https://api.ngc.nvidia.com/v2/resources/nvidia/clara/parabricks_deepvariant_retraining_notebook/versions/4.0.0-1/files/parabricks_deepvariant_retraining_notebook.zip"

    command {
        wget --content-disposition ~{shuffle_data_script_link} && \
            unzip parabricks_deepvariant_retraining_notebook.zip &&
            python3 scripts/shuffle_tfrecords_lowmem.py \
                --input_pattern_list=~{input_pattern_list} \
                --output_pattern_prefix=~{output_pattern_prefix} \
                --output_dataset_config=~{output_dataset_config} \
                --output_dataset_name=~{output_dataset_name} \
                --direct_num_workers=8 \
                --step=-1
    }

    output {

    }

    # Note: This step does not use the GPU 
    runtime {
        docker: "tensorflow/tensorflow"
        cpu: 48
        memory: "192GiB"
    }
}

task training {

    input {
        String training_output_dataset_config
        String validation_output_dataset_config
        Int? number_of_steps = 5000
        Int? batch_size = 32 
        Float? learning_rate = 0.0005
        Int? save_interval_secs = 300 
    }

    String bin_version = "1.4.0"
    String training_dir = "training"

    String model_bucket="gs://deepvariant/models/DeepVariant/~{bin_version}/DeepVariant-inception_v3-~{bin_version}+data-wgs_standard"
    String gcs_pretrained_wgs_model="~{model_bucket}/model.ckpt"

    String docker_image = "google/deepvariant:~{bin_version}-gpu"

    # TODO: How do you call put two commands here? Do you need "&&"? 
    command {

        /opt/deepvariant/bin/model_eval \
            --dataset_config_pbtxt=~{training_output_dataset_config} \
            --checkpoint_dir=~{training_dir} \
            --batch_size=512 &

        /opt/deepvariant/bin/model_train \
            --dataset_config_pbtxt=~{validation_output_dataset_config} \
            --train_dir=~{training_dir} \
            --model_name="inception_v3" \
            --number_of_steps=~{number_of_steps} \
            --save_interval_secs=~{save_interval_secs} \
            --batch_size=~{batch_size} \
            --learning_rate=~{learning_rate} \
            --start_from_checkpoint="~{gcs_pretrained_wgs_model}"
    }

    output {

    }

    runtime {
        docker: "~{docker_image}"
        acceleratorType: "nvidia-tesla-t4"
        acceleratorCount: 4
        cpu: 48
        memory: "192GiB"
    }
}



workflow DeepVariant_Retraining {

    input {

        # Make Examples 
        File ref
        File bam
        File truth_vcf 
        File truth_bed 

        String training_region
        String validation_region

        File? training_examples = "training_set_gpu.with_label.tfrecord.gz"
        File? validation_examples = "validation_set_gpu.with_label.tfrecord.gz"

        # Shuffle Data 
        String? training_input_pattern_list = "training_set_gpu.with_label.tfrecord-?????-of-00004.gz"
        String? training_output_pattern_prefix = "training_set_gpu.with_label.shuffled"
        String? training_output_dataset_config = "training_set_gpu.pbtxt"
        String? training_output_dataset_name = "HG001"

        String? validation_input_pattern_list = "validation_set_gpu.with_label.tfrecord-?????-of-00004.gz"
        String? validation_output_pattern_prefix = "validation_set_gpu.with_label.shuffled"
        String? validation_output_dataset_config = "validation_set_gpu.pbtxt"
        String? validation_output_dataset_name = "HG001"

        # Training 
        Int? number_of_steps = 5000
        Int? batch_size = 32 
        Float? learning_rate = 0.0005
        Int? save_interval_secs = 300 
    }

    ## Make training examples 
    ## Alias these with "as" 
    call make_examples as make_examples_train {
        input:
            ref=ref
            bam=bam
            truth_vcf=truth_vcf
            truth_bed=truth_bed
            examples=training_examples
            region=training_region
    }

    ## Make validation examples 
    call make_examples as make_examples_val {
        input:
            ref=ref
            bam=bam
            truth_vcf=truth_vcf
            truth_bed=truth_bed
            examples=validation_examples
            region=validation_region
    }

    ## Shuffle training data 
    call shuffle_data as shuffle_data_train {
        input: 
            vcf=make_examples_train.output_vcf ## This is just an example to capture previous output 
            input_pattern_list=training_input_pattern_list
            output_pattern_prefix=training_output_pattern_prefix
            output_dataset_config=training_output_dataset_config
            output_dataset_name=training_output_dataset_name
    }

    ## Shuffle validation data 
    call shuffle_data as shuffle_data_val {
        input: 
            input_pattern_list=validation_input_pattern_list
            output_pattern_prefix=validation_output_pattern_prefix
            output_dataset_config=validation_output_dataset_config
            output_dataset_name=validation_output_dataset_name
    }

    call training{
        input: 
            training_output_dataset_config=training_output_dataset_config
            validation_output_dataset_config=validation_output_dataset_config
            number_of_steps=number_of_steps
            batch_size =batch_size
            learning_rate=learning_rate
            save_interval_secs=save_interval_secs
    }

    ## Anything the end user should be interested in (from any of the previous tasks)
    ## These get stored in the Terra data table 
    output {
        performance_file=training.performance_file ## Example
    }

    meta {
        Author: "NVIDIA Parabricks"
    }
}