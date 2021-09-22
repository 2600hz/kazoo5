RELX = $(DEPS_DIR)/relx

$(RELX):
	wget 'https://erlang.mk/res/relx-v3.27.0' -O $@
	chmod +x $@

.PHONY: clean-release
clean-release:
	$(if $(wildcard _rel/), rm -r _rel/)

.PHONY: build-release
build-release: $(RELX) clean-release $(ROOT)/rel/relx.config $(ROOT)/rel/relx.config.script $(ROOT)/rel/sys.config $(ROOT)/rel/vm.args
	$(RELX) --config $(ROOT)/rel/relx.config -V 2 release --relname 'kazoo'

.PHONY: build-dev-release
build-dev-release: $(RELX) clean-release $(ROOT)/rel/dev.relx.config $(ROOT)/rel/dev.relx.config.script $(ROOT)/rel/dev.vm.args $(ROOT)/rel/dev.sys.config
	$(RELX) --dev-mode true --config $(ROOT)/rel/dev.relx.config -V 2 release --relname 'kazoo'

.PHONY: build-ci-release
build-ci-release: $(RELX) clean-release $(ROOT)/rel/ci.relx.config $(ROOT)/rel/ci.relx.config.script $(ROOT)/rel/ci.sys.config $(ROOT)/rel/ci.vm.args
	$(RELX) --config $(ROOT)/rel/ci.relx.config -V 2 release --relname 'kazoo'

.PHONY: build-dist-release
build-dist-release: $(RELX) clean-release $(ROOT)/rel/dist.relx.config $(ROOT)/rel/dist.relx.config.script $(ROOT)/rel/dist.vm.args $(ROOT)/rel/dist.sys.config
	$(RELX) --config $(ROOT)/rel/dist.relx.config -V 2 release --relname 'kazoo'

.PHONY: tar-release
tar-release: $(RELX) $(ROOT)/rel/relx.config $(ROOT)/rel/relx.config.script $(ROOT)/rel/sys.config $(ROOT)/rel/vm.args
	$(RELX) --config $(ROOT)/rel/relx.config -V 2 release tar --relname 'kazoo'

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
