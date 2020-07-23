## Makefile that goes in applications/
MS = $(sort $(wildcard */Makefile))

ifeq ($(strip $(APPS_MK)),)
	MAKEDIRS ?= $(MS:/Makefile=)
else
	include $(APPS_MK)
	MAKEDIRS = $(DEPS)
endif

.PHONY: all
all: compile

.PHONY: compile
compile: ACTION = all
compile: $(MAKEDIRS)

.PHONY: compile-lean
compile-lean: ACTION = compile-lean
compile-lean: $(MAKEDIRS)

.PHONY: compile-test
compile-test: ACTION = compile-test
compile-test: $(MAKEDIRS)

.PHONY: compile-test-direct
compile-test-direct: ACTION = compile-test-direct
compile-test-direct: $(MAKEDIRS)

.PHONY: clean
clean: ACTION = clean
clean: $(MAKEDIRS)

.PHONY: clean-test
clean-test: ACTION = clean-test
clean-test: $(MAKEDIRS)

.PHONY: eunit
eunit: ACTION = eunit
eunit: $(MAKEDIRS)

.PHONY: test
test: ACTION = test
test: $(MAKEDIRS)

.PHONY: $(MAKEDIRS)
$(MAKEDIRS):
	@ROOT=$(ROOT) $(MAKE) -C $(ROOT)/applications/$@ $(ACTION)
