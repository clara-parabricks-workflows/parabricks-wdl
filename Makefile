ROOT_DIR := .
SUBDIRS := $(shell find $(ROOT_DIR) -mindepth 1 -maxdepth 1 -type d)
SUBDIR_NAMES := $(notdir $(SUBDIRS))
DOWNLOAD_DATA_SCRIPT := download_data.sh

.PHONY: all run-all $(SUBDIR_NAMES)  

all: run-all

run-all: $(SUBDIR_NAMES)

$(SUBDIR_NAMES):
	@echo "Downloading test files for $@..."
	@if [ -f $(ROOT_DIR)/$@/$(DOWNLOAD_DATA_SCRIPT) ]; then \
		cd $(ROOT_DIR)/$@ && \
		bash $(DOWNLOAD_DATA_SCRIPT); \
	fi

clean: 
	rm -rf $(ROOT_DIR)/data

ifneq ($(MAKECMDGOALS),)
  SUBDIR_NAMES := $(filter $(MAKECMDGOALS), $(SUBDIR_NAMES))
endif