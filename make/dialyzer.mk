PLT = $(ROOT)/.kazoo.plt

DIALYZER ?= dialyzer
DIALYZER += --statistics --no_native

OTP_APPS ?= erts kernel stdlib crypto public_key ssl asn1 inets xmerl

CI_DIALYZER_OUTPUT ?= dialyzer_output.log
CHECK_DIALYZER_OPTS =

ifneq ($(DIALYZER_OUTPUT),)
	CHECK_DIALYZER_OPTS := --output-file $(DIALYZER_OUTPUT)
else
ifneq ($(CIRCLECI),)
	CHECK_DIALYZER_OPTS := --output-file $(CI_DIALYZER_OUTPUT)
endif
endif

EXCLUDE_DEPS = $(DEPS_DIR)/erlang_localtime/ebin
$(PLT): DEPS_EBIN ?= $(filter-out $(EXCLUDE_DEPS),$(wildcard $(DEPS_DIR)/*/ebin))
# $(PLT): CORE_EBINS ?= $(shell find $(CORE_DIR) -name ebin)
$(PLT):
	@-$(DIALYZER) --build_plt --output_plt $(PLT) \
	     --apps $(OTP_APPS) \
	     -r $(DEPS_EBIN)
	@for ebin in $(CORE_EBINS); do \
	     $(DIALYZER) --add_to_plt --plt $(PLT) --output_plt $(PLT) -r $$ebin; \
	 done

.PHONY: build-plt
build-plt: $(PLT)

.PHONY: clean-plt
clean-plt:
	@rm -f $(PLT)

.PHONY: dialyze-kazoo
dialyze-kazoo: TO_DIALYZE  = $(shell find $(APPS_DIR) $(CORE_DIR) -name ebin)
dialyze-kazoo: dialyze

.PHONY: dialyze-apps
dialyze-apps:  TO_DIALYZE  = $(shell find $(APPS_DIR) -name ebin)
dialyze-apps: dialyze

.PHONY: dialyze-core
dialyze-core:  TO_DIALYZE  = $(shell find $(CORE_DIR)         -name ebin)
dialyze-core: dialyze-it

.PHONY: dialyze
dialyze:       TO_DIALYZE ?= $(shell find $(APPS_DIR) -name ebin)
dialyze: dialyze-it

.PHONY: dialyze-changed
dialyze-changed: CHECK_DIALYZER_OPTS += --bulk
dialyze-changed: dialyze-it-changed

.PHONY: dialyze-hard
dialyze-hard: CHECK_DIALYZER_OPTS += --hard
dialyze-hard: dialyze-it-changed

.PHONY: dialyze-types-kazoo
dialyze-types-kazoo: TO_DIALYZE  = $(shell find $(APPS_DIR) $(CORE_DIR) -name ebin)
dialyze-types-kazoo: dialyze-types-it

.PHONY: dialyze-types
dialyze-types: TO_DIALYZE = $(CHANGED)
dialyze-types: $(PLT) dialyze-types-it

dialyze-types-it:
	@echo ":: dialyzing types"
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(if $(DEBUG),time -v) $(ROOT)/scripts/check-dialyzer-types.escript $(ROOT)/.kazoo.plt $(CHECK_DIALYZER_OPTS) $(strip $(filter %.beam %.erl %/ebin,$(TO_DIALYZE))) && echo "dialyzer is happy!"

.PHONY: dialyze-it
dialyze-it: $(PLT)
	@echo ":: dialyzing"
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(if $(DEBUG),time -v) $(ROOT)/scripts/check-dialyzer.escript $(ROOT)/.kazoo.plt $(CHECK_DIALYZER_OPTS) $(strip $(filter %.beam %.erl %/ebin,$(TO_DIALYZE))) && echo "dialyzer is happy!"

.PHONY: dialyze-it-changed
dialyze-it-changed: export TO_DIALYZE = $(CHANGED)
dialyze-it-changed: $(PLT)
	@if [ -n "$(TO_DIALYZE)" ]; then \
		echo "dialyzing changes against $(BASE_BRANCH)" ; \
		$(MAKE) dialyze-it; \
	else \
		echo "no erlang changes to dialyze"; \
	fi

.PHONY: diff
diff: export TO_DIALYZE = $(CHANGED)
diff: dialyze-it
