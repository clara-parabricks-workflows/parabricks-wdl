WOMTOOL := womtool-81.jar

WDL_DIR := wdl
WDL_FILES = $(wildcard $(WDL_DIR)/*.wdl)

VAL_DIR := .validate

VALS := $(patsubst %.wdl, $(VAL_DIR)/%.val, $(notdir $(WDL_FILES)))

$(VAL_DIR)/%.val : $(WDL_DIR)/%.wdl pre
	+java -jar $(WOMTOOL) validate $< | tee $@

validate: $(VALS) pre

pre:
	mkdir -p $(VAL_DIR)

clean:
	rm -rf $(VAL_DIR)

.PHONY: validate inputs clean pre minimal_inputs full_inputs
