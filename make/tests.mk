.PHONY: clean-test
clean-test: clean-test-core clean-test-apps

.PHONY: clean-test-core
clean-test-core:
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(CORE_DIR) clean-test

.PHONY: clean-test-apps
clean-test-apps:
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(APPS_DIR) clean-test

.PHONY: compile-proper
compile-proper: ERLC_OPTS += -DPROPER
compile-proper: compile-test

.PHONY: compile-test
compile-test: ERLC_OPTS += +nowarn_missing_spec
compile-test: compile-test-core compile-test-apps

.PHONY: compile-test-core
compile-test-core: deps fetch-core
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(CORE_DIR) compile-test-direct

.PHONY: compile-test-apps
compile-test-apps: deps fetch-apps
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(APPS_DIR) compile-test-direct

.PHONY: eunit
eunit: eunit-core eunit-apps

.PHONY: eunit-core
eunit-core: deps $(CORE_HASH_FILE)
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(CORE_DIR) eunit

.PHONY: eunit-apps
eunit-apps: deps fetch-apps
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(APPS_DIR) eunit

.PHONY: proper
proper: ERLC_OPTS += -DPROPER
proper: proper-core proper-apps

.PHONY: proper-core
proper-core: deps $(CORE_HASH_FILE)
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(CORE_DIR) proper

.PHONY: proper-apps
proper-apps: deps fetch-apps
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(APPS_DIR) proper

.PHONY: test
test: ERLC_OPTS += -DPROPER
test: ERLC_OPTS += +nowarn_missing_spec
test: test-core test-apps

.PHONY: test-core
test-core: deps $(CORE_HASH_FILE)
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(CORE_DIR) test

.PHONY: test-apps
test-apps: deps fetch-apps
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(APPS_DIR) test

.PHONY: coverage-report
coverage-report:
	$(ROOT)/scripts/cover.escript

.PHONY: check
check: ERLC_OPTS += -DPROPER
check: compile-test eunit clean-kazoo kazoo
