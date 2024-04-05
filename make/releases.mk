RELX = $(ROOT)/scripts/build-release.escript

RELX_CONFIG = $(ROOT)/rel/relx.config
RELX_CONFIG_SCRIPT = $(RELX_CONFIG).script

.PHONY: clean-release
clean-release:
	$(if $(wildcard _rel/), rm -r _rel/)

.PHONY: build-release
build-release: $(RELX) clean-release $(RELX_CONFIG) $(RELX_CONFIG_SCRIPT) $(ROOT)/rel/sys.config $(ROOT)/rel/vm.args
	ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(RELX) --config $(RELX_CONFIG)

.PHONY: build-dev-release
build-dev-release: $(RELX) clean-release $(ROOT)/rel/dev.relx.config $(ROOT)/rel/dev.relx.config.script $(ROOT)/rel/dev.vm.args $(ROOT)/rel/dev.sys.config
	ERL_LIBS=$(DEPS_DIR):$(CORE_DIR) $(RELX) --config $(ROOT)/rel/dev.relx.config

.PHONY: build-ci-release
build-ci-release: $(RELX) clean-release $(ROOT)/rel/ci.relx.config $(ROOT)/rel/ci.relx.config.script $(ROOT)/rel/ci.sys.config $(ROOT)/rel/ci.vm.args
	ERL_LIBS=$(DEPS_DIR):$(CORE_DIR) $(RELX) --config $(ROOT)/rel/ci.relx.config

.PHONY: build-dist-release
build-dist-release: $(RELX) clean-release $(ROOT)/rel/dist.relx.config $(ROOT)/rel/dist.relx.config.script $(ROOT)/rel/dist.vm.args $(ROOT)/rel/dist.sys.config
	ERL_LIBS=$(DEPS_DIR):$(CORE_DIR) $(RELX) --config $(ROOT)/rel/dist.relx.config

.PHONY: tar-release
tar-release: $(RELX) $(RELX_CONFIG) $(RELX_CONFIG_SCRIPT) $(ROOT)/rel/sys.config $(ROOT)/rel/vm.args
	$(RELX) --config $(RELX_CONFIG) -V 2 release tar --relname 'kazoo'

## More ACTs at //github.com/erlware/relx/priv/templates/extended_bin
.PHONY: release
release: ACT ?= console # start | attach | stop | console | foreground
release: REL ?= kazoo_apps # kazoo_apps | ecallmgr | …
release: COOKIE ?= change_me
release:
	NODE_NAME="$(REL)" COOKIE="$(COOKIE)" $(ROOT)/scripts/dev/kazoo.sh $(ACT) "$$@"

.PHONY: install
install: compile build-release
	cp -a _$(ROOT)/rel/kazoo /opt

.PHONY: read-release-cookie
read-release-cookie: REL ?= kazoo_apps
read-release-cookie:
	@NODE_NAME='$(REL)' _$(ROOT)/rel/kazoo/bin/kazoo escript lib/kazoo_config-*/priv/read-cookie.escript "$$@"
