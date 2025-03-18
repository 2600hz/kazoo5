ifndef VERBOSE
MAKEFLAGS += --no-print-directory
endif

ROOT := $(shell cd "$(dirname '.')" && pwd -P)

DEPS_DIR = $(ROOT)/deps
CORE_DIR = $(ROOT)/core
APPS_DIR = $(ROOT)/applications

TAGS = $(ROOT)/TAGS
ERLANG_LS = $(ROOT)/erlang_ls.config
KZ_VSCODE = $(ROOT)/kazoo.code-workspace
KZ_VSCODE_DEBUGGER = $(ROOT)/.vscode/launch.json

ERLANG_MK = $(ROOT)/erlang.mk
DOT_ERLANG_MK = $(ROOT)/.erlang.mk

# erlang.mk
ERLANG_MK_REPO ?= https://github.com/ninenines/erlang.mk
ERLANG_MK_BUILD_CONFIG ?= build.config
ERLANG_MK_BUILD_DIR ?= .erlang.mk.build

# fixing erlang.mk to a commit, until elixir detection gets fixed
ERLANG_MK_COMMIT ?= 3f7955bad270767f87272f1066ecb0a7ae0c7914
export ERLANG_MK_COMMIT

# disabling elixir in erlang.mk
ELIXIR ?= disable
export ELIXIR

## If you use SSH keys instead
## FETCH_AS = git@github.com:
FETCH_AS ?= https://github.com/

BASE_BRANCH := $(shell cat $(ROOT)/.base_branch)

DEPS_HASH := $(shell md5sum $(ROOT)/make/deps.mk | cut -d' ' -f1)
DEPS_HASH_FILE := $(ROOT)/make/.deps.mk.$(DEPS_HASH)

APPS_HASH := $(shell md5sum $(ROOT)/make/apps.mk | cut -d' ' -f1)
APPS_HASH_FILE := $(ROOT)/make/.apps.mk.$(APPS_HASH)

APP_URLS_HASH := $(shell md5sum $(ROOT)/make/app_urls.mk | cut -d' ' -f1)
APP_URLS_HASH_FILE := $(ROOT)/make/.app_urls.mk.$(APP_URLS_HASH)

CORE_HASH := $(shell md5sum $(ROOT)/make/Makefile.core | cut -d' ' -f1)
CORE_HASH_FILE := $(ROOT)/make/.core.mk.$(CORE_HASH)

APPS := $(dir $(wildcard $(APPS_DIR)/*/.git))
CORE := $(wildcard $(CORE_DIR))/

KAST = $(APPS_DIR)/ast

## list files changed for more focused checks
ifeq ($(strip $(CHANGED)),)
ifeq ($(CIRCLECI),)
	CHANGED := $(strip $(shell $(ROOT)/scripts/check-changed.bash $(ROOT) $(CORE) $(APPS)))
else
    CHANGED := $(CHANGED)
endif
else
	CHANGED := $(CHANGED)
endif

STATUS = $($(ROOT)/scripts/check-git-status.bash $(ROOT) $(CORE_DIR) $(APPS))

CHANGED_SWAGGER ?= $(shell $(ROOT)/kgit -kapps crossbar git --no-pager diff --name-only HEAD $(BASE_BRANCH) -- priv/api/swagger.json)
CHANGED_ERL=$(filter %.hrl %.erl %.escript,$(CHANGED))
CHANGED_APPS=$(filter $(APPS_DIR)%,$(CHANGED_ERL))
CHANGED_JSON=$(filter %.json,$(CHANGED))
CHANGED_YML=$(filter %.yml,$(CHANGED))
CHANGED_DOCS=$(filter %.md,$(CHANGED))

PRINTABLE_CHANGED=$(subst $(ROOT),,$(CHANGED))
PRINTABLE_ERL=$(subst $(ROOT),,$(CHANGED_ERL))
PRINTABLE_APPS=$(sort $(foreach app,$(CHANGED_APPS),$(firstword $(subst /, ,$(subst $(APPS_DIR)/,,$(app))))))
PRINTABLE_JSON=$(subst $(ROOT),,$(CHANGED_JSON))
PRINTABLE_YML=$(subst $(ROOT),,$(CHANGED_YML))
PRINTABLE_DOCS=$(subst $(ROOT),,$(CHANGED_DOCS))

# exporting these so they are used in targets
export CHANGED
export CHANGED_SWAGGER
export CHANGED_ERL
export CHANGED_APPS
export CHANGED_JSON
export CHANGED_YML
export CHANGED_DOCS

# You can override this when calling make, e.g. make JOBS=1
# to prevent parallel builds, or make JOBS="8".
JOBS ?= 1
CLEAN_JOBS ?=

.PHONY: all
all: prerequisites compile

.PHONY: changed
changed:
	@echo "chapps: $(CHANGED_APPS)"
	@$(ROOT)/scripts/pretty-print-files.bash "changed:" $(PRINTABLE_CHANGED)
	@$(ROOT)/scripts/pretty-print-files.bash "changed ERL:" $(PRINTABLE_ERL)
	@$(ROOT)/scripts/pretty-print-files.bash "changed APPS:" $(PRINTABLE_APPS)
	@$(ROOT)/scripts/pretty-print-files.bash "changed JSON:" $(PRINTABLE_JSON)
	@$(ROOT)/scripts/pretty-print-files.bash "changed YML:" $(PRINTABLE_YML)
	@$(ROOT)/scripts/pretty-print-files.bash "changed docs:" $(PRINTABLE_DOCS)

.PHONY: unstaged
unstaged:
	$(ROOT)/scripts/check-unstaged.bash

.PHONY: changed_swagger
changed_swagger:
	@echo "$(CHANGED_SWAGGER)"

.PHONY: prerequisites
prerequisites: make-dependency-check rebar

.PHONY: make-dependency-check
make-dependency-check:
	$(ROOT)/scripts/make-prerequisite.sh

.PHONY: compile-lean compile-lean-core compile-lean-apps
compile-lean: ACTION = compile-lean
compile-lean: deps compile-lean-core compile-lean-apps
compile-lean-core:
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C core/ compile-lean
compile-lean-apps:
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C applications/ compile-lean

.PHONY: compile
compile: ACTION = all
compile: deps kazoo

.PHONY: sparkly-clean
sparkly-clean: stop-if-changed clean-kazoo clean-release clean-deps clean-tags
	 @(rm -rf $(APPS_DIR) $(CORE_DIR))

.PHONY: stop-if-changed
stop-if-changed:
	@[ -z "$(CHANGED)" ] && exit 0 || `echo Unstaged changes make this unsage && exit 1`

.PHONY: clean-kazoo
clean-kazoo: stop-if-changed
	@$(ls -d $(APPS_DIR)/* | xargs rm -rf)
	@$(rm -rf $(CORE_DIR))
	@$(if $(wildcard $(CORE_HASH_FILE)), rm -rf $(CORE_HASH_FILE))
	@$(if $(wildcard $(APPS_HASH_FILE)), rm -rf $(APPS_HASH_FILE))
	@$(if $(wildcard $(APP_URLS_HASH_FILE)), rm -rf $(APP_URLS_HASH_FILE))

.PHONY: clean
clean: clean-core clean-apps
	$(if $(wildcard *crash.dump), rm *crash.dump)
	$(if $(wildcard scripts/log/*), rm -rf scripts/log/*)
	$(if $(wildcard rel/dev-vm.args), rm rel/dev-vm.args)

.PHONY: clean-core
clean-core:
	@$(if $(wildcard $(CORE_DIR)),ROOT=$(ROOT) $(MAKE) -j$(CLEAN_JOBS) -C $(CORE_DIR) clean)

.PHONY: clean-apps
clean-apps:
	@$(if $(wildcard $(APPS_DIR)/Makefile),ROOT=$(ROOT) $(MAKE) -j$(CLEAN_JOBS) -C $(APPS_DIR) clean)

.PHONY: clean-deps
clean-deps: clean-deps-hash
	@$(if $(wildcard $(DEPS_DIR)), rm -rf $(DEPS_DIR))
	@$(if $(wildcard $(DOT_ERLANG_MK)), rm -rf $(DOT_ERLANG_MK))
	@$(if $(wildcard $(ERLANG_MK)), rm -r $(ERLANG_MK))
	@echo "Cleaned deps-related files"

.PHONY: clean-deps-hash
clean-deps-hash:
	$(if $(wildcard $(ROOT)/make/.deps.mk.*), rm $(ROOT)/make/.deps.mk.*)

.PHONY=dot_erlang_mk
dot_erlang_mk: $(DOT_ERLANG_MK)

$(DOT_ERLANG_MK): $(ERLANG_MK)

$(ERLANG_MK):
	@# This is the exactly what https://erlang.mk/erlang.mk is doing, just adds the checkout part
ifdef ERLANG_MK_COMMIT
	git clone $(ERLANG_MK_REPO) $(ERLANG_MK_BUILD_DIR)
	cd $(ERLANG_MK_BUILD_DIR) && git checkout $(ERLANG_MK_COMMIT)
else
	git clone --depth 1 $(ERLANG_MK_REPO) $(ERLANG_MK_BUILD_DIR)
endif
	if [ -f $(ERLANG_MK_BUILD_CONFIG) ]; then cp $(ERLANG_MK_BUILD_CONFIG) $(ERLANG_MK_BUILD_DIR); fi
	cd $(ERLANG_MK_BUILD_DIR) && $(MAKE)
	cp $(ERLANG_MK_BUILD_DIR)/erlang.mk ./erlang.mk
	rm -rf $(ERLANG_MK_BUILD_DIR)

.PHONY: deps
deps: $(DEPS_HASH_FILE)

$(DEPS_HASH_FILE):
	@$(MAKE) clean-deps
	@$(MAKE) $(DEPS_DIR)/Makefile
	ROOT=$(ROOT) $(MAKE) -C $(DEPS_DIR)/ deps
	@touch $(DEPS_HASH_FILE)

$(DEPS_DIR)/Makefile: $(DOT_ERLANG_MK) $(DEPS_DIR) clean-plt
	@cp $(ROOT)/make/Makefile.deps $(DEPS_DIR)/Makefile
	@$(MAKE) -f $(ERLANG_MK) deps

$(DEPS_DIR):
	@mkdir -p $(DEPS_DIR)

# Target: core
# 1. make sure the 'deps' target is built
# 2. make sure the core repo has been fetched (using the hash of the make/Makefile.core as a check)
# Once satisfied, compile all the dirs under core/
.PHONY: core
core: deps fetch-core
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(CORE_DIR) all

# Target: fetch-core
# Alias for $(CORE_DIR)Makefile to fetch the core apps
fetch-core: $(CORE_HASH_FILE) $(CORE_DIR)/Makefile

# Target: core hash file
# 1. Make sure erlang.mk is setup
# 2. Make sure core/Makefile exists
# Once satisfied, create the core hash file
$(CORE_HASH_FILE): $(CORE_DIR)/Makefile
	@touch $(CORE_HASH_FILE)

# Target: core/Makefile
# Using make/Makefile.core, use erlang.mk to fetch the kazoo-core repo (which includes the Makefile needed)
$(CORE_DIR)/Makefile: $(DOT_ERLANG_MK)
	@NO_AUTOPATCH_ERLANG_MK=1 $(MAKE) -f $(ROOT)/make/Makefile.core fetch-deps

# Target: apps
# Since kazoo-core comes with a Makefile for building all apps under it, erlang.mk is used to fetch deps
# Since each app is fetched independently, use erlang.mk to call the Makefile in each fetched app
# 1. Make sure core is built
# 2. Check the apps hash file (hash of make/apps.mk)
# Once satisfied, use erlang.mk to fetch the apps (via the erlang.mk deps target), and compile all the apps
.PHONY: apps
apps: core fetch-apps
	@ROOT=$(ROOT) $(MAKE) -j$(JOBS) -C $(APPS_DIR) all

fetch-apps: $(APPS_HASH_FILE) $(APP_URLS_HASH_FILE) $(APPS_DIR)/Makefile
	@NO_AUTOPATCH_ERLANG_MK=1 ROOT=$(ROOT) $(MAKE) -f $(ROOT)/make/Makefile.apps -C $(APPS_DIR) fetch-deps

# Target: apps hash file
# 1. Make sure elrang.mk is setup
# Once satisfied, create the applications directory and the apps hash file
$(APPS_HASH_FILE): $(DOT_ERLANG_MK) make/more_apps.mk
	@touch $(APPS_HASH_FILE)

$(APP_URLS_HASH_FILE):
	@touch $(APP_URLS_HASH_FILE)

# Bootstrap more_apps.mk with kazoo_properly and kazoo_ast
make/more_apps.mk:
	@cp make/more_apps.mk.default make/more_apps.mk

.PHONY: apps-makefile
apps-makefile: $(APPS_DIR)/Makefile

$(APPS_DIR)/Makefile:
	@$(shell mkdir -p $(APPS_DIR))
	@cp $(ROOT)/make/Makefile.applications $(APPS_DIR)/Makefile

.PHONY: kazoo
kazoo: deps apps $(TAGS)

.PHONY: tags
tags:
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) ./scripts/tags.escript $(TAGS)

$(TAGS): tags

.PHONY: clean-tags
clean-tags:
	$(if $(wildcard $(TAGS)), rm $(TAGS))

.PHONY: fixture_shell
fixture_shell: ERL_CRASH_DUMP = "$(ROOT)/$(shell date +%s)_ecallmgr_erl_crash.dump"
fixture_shell: ERL_LIBS = "$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR):$(shell echo $(DEPS_DIR)/rabbitmq_erlang_client-*/deps)"
fixture_shell: NODE_NAME ?= fixturedb
fixture_shell:
	@ERL_CRASH_DUMP="$(ERL_CRASH_DUMP)" ERL_LIBS="$(ERL_LIBS)" KAZOO_CONFIG=$(ROOT)/rel/config-test.ini \
		erl -setcookie change_me -name '$(NODE_NAME)' -s reloader "$$@"

.PHONY: xref
xref: TO_XREF ?= $(shell find $(APPS_DIR) $(CORE_DIR) $(DEPS_DIR) -name ebin)
xref:
	@$(ROOT)/scripts/check-xref.escript $(TO_XREF)

.PHONY: xref_release
xref_release: TO_XREF = $(shell find $(ROOT)/_rel/kazoo/lib -name ebin)
xref_release:
	@$(ROOT)/scripts/check-xref.escript $(TO_XREF)

.PHONY: sup_completion
sup_completion: sup_completion_file = $(ROOT)/sup.bash
sup_completion:
	@$(if $(wildcard $(sup_completion_file)), rm $(sup_completion_file))
	@$(CORE_DIR)/sup/priv/build-autocomplete.escript $(sup_completion_file) $(APPS_DIR) $(CORE_DIR)
	@echo SUP Bash completion file written at $(sup_completion_file)

.PHONY: bump-copyright
bump-copyright:
	@$(ROOT)/scripts/bump-copyright-year.py $(shell find $(APPS_DIR) $(CORE_DIR) -name '*.erl')

.PHONY: bump-license
bump-license:
	@$(ROOT)/scripts/bump-license.py $(shell find $(APPS_DIR) $(CORE_DIR) -name '*.erl')

.PHONY: app_applications
app_applications:
app_applications:
	ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/apps_of_app.escript -a $(PRINTABLE_APPS)

.PHONY: code_checks
code_checks: bump-changed-copyright bump-changed-license edoc splchk-common raw-json
	@printf "\n:: Check code\n\n"
	@$(ROOT)/scripts/code_checks.bash $(CHANGED_ERL)
	@printf "\n:: Check for Kazoo diaspora\n\n"
	@$(ROOT)/scripts/kz_diaspora.bash
	@printf "\n:: Check for Kazoo document accessors\n\n"
	@$(ROOT)/scripts/kzd_module_check.bash
	@printf "\n:: Check for proper log message usage\n\n"
	@$(ROOT)/scripts/check-loglines.bash $(CHANGED_ERL)
	@printf "\n:: Check for Erlang 21 new stacktrace syntax\n\n"
	@$(ROOT)/scripts/check-stacktrace.py $(CHANGED_ERL)

.PHONY: raw-json
raw-json:
	@printf "\n:: Check for raw JSON usage\n\n"
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/no_raw_json.escript $(CHANGED_ERL)

.PHONY: edoc
edoc:
	@printf "\n:: Check for Edoc\n\n"
	@CHANGED_ERL="$(CHANGED_ERL)" $(ROOT)/scripts/edocify.escript

.PHONY: bump-changed-copyright
bump-changed-copyright:
	@printf ":: Check for copyright year\n\n"
	@$(ROOT)/scripts/bump-copyright-year.py $(CHANGED_ERL)

.PHONY: bump-changed-license
bump-changed-license:
	@printf ":: Check for license\n\n"
	@$(ROOT)/scripts/bump-license.py $(CHANGED_ERL)

.PHONY: raw_json_check
raw_json_check:
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/no_raw_json.escript

.PHONY: check_stacktrace
check_stacktrace:
	@$(ROOT)/scripts/check-stacktrace.py $(shell grep -rl "get_stacktrace" scripts $(APPS_DIR) $(CORE_DIR) --include "*.[e|h]rl" --exclude "kz_types.hrl")

## FIXME: `format-couchdb-view.py` command is a copy-paste from fmt.mk
## Adding this format couchdb view target to circleci steps for every app is painful
## also this formatting is better to be done before validate-js ci step to make sure
## the view is still in correct shape
apis: schemas api_endpoints kzd_builder
	@$(ROOT)/scripts/generate-doc-schemas.py `egrep -rl '(#+) Schema' core/ applications/ | grep -v '.[h|e]rl'`
	@$(ROOT)/scripts/format-json.py $(APPS_DIR)/crossbar/priv/api/swagger.json
	@$(ROOT)/scripts/format-json.py $(shell find $(APPS_DIR) $(CORE_DIR) -wholename '*/api/*.json')
	@$(ROOT)/scripts/format-couchdb-views.py $(shell find $(CORE_DIR)/kazoo_apps/priv/couchdb/account -name '*.json')
	@$(ROOT)/scripts/format-couchdb-views.py $(shell find $(APPS_DIR) $(CORE_DIR) -wholename '*/couchdb/views/*.json')

.PHONY: kzd_builder
kzd_builder:
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/generate-kzd-builders.escript

.PHONY: schemas
schemas: $(KAST)
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/generate-schemas.escript $(CHANGED_ERL)
	@$(ROOT)/scripts/format-json.py $(shell find $(APPS_DIR) $(CORE_DIR) -wholename '*/schemas/*.json')

.PHONY: api_endpoints
api_endpoints:
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/generate-api-endpoints.escript

$(KAST):
	@DEPS=ast ROOT=$(ROOT) $(MAKE) -f $(ROOT)/make/Makefile.apps -C $(APPS_DIR)

.PHONY: validate-swagger
validate-swagger:
	@$(ROOT)/scripts/validate-swagger.py

.PHONY: validate-js
validate-js:
	@$(ROOT)/scripts/validate-js.py $(CHANGED_JSON)

.PHONY: sdks
sdks:
	@$(ROOT)/scripts/make-swag.sh

.PHONY: validate-schemas
validate-schemas:
	@$(ROOT)/scripts/validate-schemas.py $(APPS_DIR)/crossbar/priv/couchdb/schemas

whitespace:
	@$(ROOT)/scripts/check-whitespace.sh $(CHANGED)

include $(ROOT)/make/rebar.mk
include $(ROOT)/make/ci.mk
include $(ROOT)/make/dialyzer.mk
include $(ROOT)/make/docs.mk
include $(ROOT)/make/editor.mk
include $(ROOT)/make/elvis.mk
include $(ROOT)/make/fmt.mk
include $(ROOT)/make/hank.mk
include $(ROOT)/make/pest.mk
include $(ROOT)/make/releases.mk
include $(ROOT)/make/splchk.mk
include $(ROOT)/make/tests.mk

circle: ci
