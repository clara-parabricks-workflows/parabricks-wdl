WOMTOOL := womtool-81.jar
PBDOCKER := "clara-parabricks/parabricks-cloud:4.0.0-1.alpha1"

WDL_DIR := wdl
WDL_FILES = $(wildcard $(WDL_DIR)/*.wdl)

VAL_DIR := .validate

VALS := $(patsubst %.wdl, $(VAL_DIR)/%.val, $(notdir $(WDL_FILES)))

$(VAL_DIR)/%.val : $(WDL_DIR)/%.wdl pre
	+java -jar $(WOMTOOL) validate $< | tee $@

validate: $(VALS) pre

set_docker: $(wildcard $(WDL_DIR)/*.wdl)
	for i in $^; do sed -i "s|pbDocker = \".*\"|pbDocker = \"$(PBDOCKER)\"|g" $$i ; done

pre:
	mkdir -p $(VAL_DIR)

clean:
	rm -rf $(VAL_DIR)

.PHONY: validate inputs clean pre minimal_inputs full_inputs set_docker
