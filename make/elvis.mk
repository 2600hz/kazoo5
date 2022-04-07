DEPS = elvis

dep_elvis = git $(FETCH_AS)2600hz/erlang-elvis 2600Hz
# used by all to check formatting

ELVIS_DEP_DIR = $(DEPS_DIR)/elvis
ELVIS = $(ROOT)/elvis

FETCH_AS ?= https://github.com/

$(ELVIS_DEP_DIR): $(DEPS_HASH_FILE)
	@echo creating elvis dir $(ELVIS_DEP_DIR)
	@mkdir -p $(ELVIS_DEP_DIR)
	ROOT=$(ROOT) DEPS_MK="$(ROOT)/make/elvis.mk" $(MAKE) -C $(DEPS_DIR)/ all

.PHONY: elvis-escript
elvis-escript:
	@ERLANG_MK_FILENAME=$(ROOT)/erlang.mk DEPS_DIR=$(ROOT)/deps ESCRIPT_NAME=elvis ESCRIPT_FILE=$(ROOT)/elvis make -C $(ELVIS_DEP_DIR) escript

$(ELVIS): $(ELVIS_DEP_DIR)
	@ERLANG_MK_FILENAME=$(ROOT)/erlang.mk DEPS_DIR=$(ROOT)/deps ESCRIPT_NAME=elvis ESCRIPT_FILE=$(ROOT)/elvis make -C $(ELVIS_DEP_DIR) escript

.PHONY: elvis
elvis: $(ELVIS)
# need $(CHANGED_ERL) absolute paths to be relative to $(ROOT)
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR) $(ELVIS) --config $(ROOT)/make/elvis.config --verbose -k --parallel auto rock $(subst $(ROOT)/,,$(CHANGED_ERL))
