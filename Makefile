WOMTOOL := womtool-81.jar
PBDOCKER := "gcr.io/clara-lifesci/parabricks-cloud:3.8.0-1"
DEFAULT_GPU_MODEL := "nvidia-tesla-t4"

WDL_DIR := wdl
WDL_FILES = $(wildcard $(WDL_DIR)/*.wdl)

VAL_DIR := .validate
INPUTS_DIR := example_inputs

VALS := $(patsubst %.wdl, $(VAL_DIR)/%.val, $(notdir $(WDL_FILES)))
MIN_INPUTS := $(patsubst %.wdl, $(INPUTS_DIR)/%.minimalInputs.json, $(notdir $(WDL_FILES)))
FULL_INPUTS := $(patsubst %.wdl, $(INPUTS_DIR)/%.fullInputs.json, $(notdir $(WDL_FILES)))

$(VAL_DIR)/%.val : $(WDL_DIR)/%.wdl pre
	+java -jar $(WOMTOOL) validate $< | tee $@

validate: $(VALS) pre

$(INPUTS_DIR)/%.minimalInputs.json : $(WDL_DIR)/%.wdl FORCE
	+java -jar $(WOMTOOL) inputs $< | grep -v "optional" | tee $@

$(INPUTS_DIR)/%.fullInputs.json : $(WDL_DIR)/%.wdl FORCE
	+java -jar $(WOMTOOL) inputs $< | tee $@

inputs: $(MIN_INPUTS) $(FULL_INPUTS)

set_docker: $(wildcard $(WDL_DIR)/*.wdl)
	for i in $^; do sed -i "s|pbDocker = \".*\"|pbDocker = \"$(PBDOCKER)\"|g" $$i ; done

set_gpu: $(wildcard $(WDL_DIR)/*.wdl)
	for i in $^; do sed -i "s|gpuModel = \".*\"|gpuModel = \"$(DEFAULT_GPU_MODEL)\"|g" $$i ; done

pre:
	mkdir -p $(VAL_DIR)

clean:
	rm -rf $(VAL_DIR)

.PHONY: validate inputs clean pre set_docker 

FORCE:
