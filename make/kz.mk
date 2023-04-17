## Kazoo Makefile targets
## Targets are run from the application's root directory (not KAZOO root).

## Platform detection.
ifeq ($(PLATFORM),)
    UNAME_S := $(shell uname -s)

    ifeq ($(UNAME_S),Linux)
        PLATFORM = linux
    else ifeq ($(UNAME_S),Darwin)
        PLATFORM = darwin
    else ifeq ($(UNAME_S),SunOS)
        PLATFORM = solaris
    else ifeq ($(UNAME_S),GNU)
        PLATFORM = gnu
    else ifeq ($(UNAME_S),FreeBSD)
        PLATFORM = freebsd
    else ifeq ($(UNAME_S),NetBSD)
        PLATFORM = netbsd
    else ifeq ($(UNAME_S),OpenBSD)
        PLATFORM = openbsd
    else ifeq ($(UNAME_S),DragonFly)
        PLATFORM = dragonfly
    else
        $(error Unable to detect platform.)
    endif

    export PLATFORM
endif

## pipefail enforces that the command fails even when run through a pipe
SHELL := /bin/bash -o pipefail

FETCH_AS ?= https://github.com/

BASE_BRANCH := $(shell cat $(ROOT)/.base_branch)


comma := ,
empty :=
space := $(empty) $(empty)

KZ_VERSION ?= $(shell $(ROOT)/scripts/next_version)

## SOURCES provides a way to specify compilation order (left to right)
SOURCES     ?= $(wildcard src/*.erl) $(wildcard src/*/*.erl)
SOURCES_FULL_PATH = $(realpath $(SOURCES))
MODULE_NAMES := $(sort $(foreach module,$(SOURCES),$(shell basename $(module) .erl)))
MODULES := $(shell echo $(MODULE_NAMES) | sed 's/ /,/g')
BEAMS := $(sort $(foreach module,$(SOURCES),ebin/$(shell basename $(module) .erl).beam))
JSON := $(shell find $(PROJECT_ROOT) -name "*.json")
DOCS ?= $(wildcard doc/*.md)

TEST_SOURCES := $(SOURCES) $(wildcard test/*.erl)
TEST_MODULE_NAMES := $(sort $(foreach module,$(TEST_SOURCES),$(shell basename $(module) .erl)))
TEST_MODULES := $(shell echo $(TEST_MODULE_NAMES) | sed 's/ /,/g')
TEST_BEAMS := $(sort $(foreach module,$(TEST_SOURCES),ebin/$(shell basename $(module) .erl).beam))

ERLC_OPTS += -Iinclude -Isrc -I../ +'{parse_transform, lager_transform}'
## Use pedantic flags when compiling apps from applications/ & core/
ERLC_OPTS += +warn_export_all +warn_unused_import +warn_unused_vars +warn_missing_spec -Werror

ifndef ERLC_OPTS_SUPERSECRET
    ERLC_OPTS += +debug_info
else
    ERLC_OPTS += $(ERLC_OPTS_SUPERSECRET)
endif

ELIBS ?= $(if $(ERL_LIBS),$(ERL_LIBS):)$(ROOT)/deps:$(ROOT)/core:$(ROOT)/applications

EBINS += $(ROOT)/deps/lager/ebin

TEST_EBINS += $(EBINS) $(ROOT)/deps/proper/ebin
PA      = -pa ebin/ $(foreach EBIN,$(EBINS),-pa $(EBIN))
TEST_PA = -pa ebin/ $(foreach EBIN,$(TEST_EBINS),-pa $(EBIN))

DEPS_RULES = .deps.rules
TEST_DEPS = $(CURDIR)/.test.deps
DEPS_MK = $(CURDIR)/deps.mk
APPS_MK = $(CURDIR)/apps.mk
DEPS_DIR = $(ROOT)/deps
CORE_DIR = $(ROOT)/core
APPS_DIR = $(ROOT)/applications
DOT_ERLANG_MK = $(ROOT)/.erlang.mk

APPS_LIST = $(file < $(APPS_MK))
APP_DIRS = $(foreach APP,$(APPS_LIST),$(wildcard $(ROOT)/applications/$(APP)))
APPS_PA = $(foreach APP,$(APP_DIRS), -pa $(APP)/ebin)

CHANGED ?= $(strip $(shell $(ROOT)/scripts/check-changed.bash $(APPS_DIR)/$(PROJECT)))

CHANGED_ERL=$(filter %.hrl %.erl %.escript,$(CHANGED))
CHANGED_JSON=$(filter %.json,$(CHANGED))
CHANGED_YML=$(filter %.yml,$(CHANGED))
CHANGED_DOCS=$(filter %.md,$(CHANGED))

PRINTABLE_CHANGED=$(subst $(ROOT),,$(CHANGED))
PRINTABLE_ERL=$(subst $(ROOT),,$(CHANGED_ERL))
PRINTABLE_JSON=$(subst $(ROOT),,$(CHANGED_JSON))
PRINTABLE_YML=$(subst $(ROOT),,$(CHANGED_YML))
PRINTABLE_DOCS=$(subst $(ROOT),,$(CHANGED_DOCS))

export CHANGED
export CHANGED_SWAGGER
export CHANGED_ERL
export CHANGED_JSON
export CHANGED_YML
export CHANGED_DOCS

.PHONY: changed
changed:
	@$(ROOT)/scripts/pretty-print-files.bash "changed:" $(PRINTABLE_CHANGED)

ifeq ($(wildcard $(DEPS_MK)),)
    $(shell touch $(DEPS_MK))
endif

ifeq ($(wildcard $(APPS_MK)),)
    $(shell touch $(APPS_MK))
endif

DEPS_HASH := $(shell md5sum $(DEPS_MK) | cut -d' ' -f1)
DEPS_HASH_FILE := .deps.mk.$(DEPS_HASH)
APPS_HASH := $(shell md5sum $(APPS_MK) | cut -d' ' -f1)
APPS_HASH_FILE := .apps.mk.$(APPS_HASH)

.PHONY: deps
deps: $(DOT_ERLANG_MK) $(DEPS_HASH_FILE)

$(DEPS_HASH_FILE):
	@if [ -s $(DEPS_MK) ]; then \
	    FETCH_AS=$(FETCH_AS) DEPS_MK="$(DEPS_MK)" $(MAKE) -C $(DEPS_DIR) all; \
	 fi
	@touch .deps.mk.$(shell md5sum $(DEPS_MK) | cut -d' ' -f1)

.PHONY: apps
apps: $(DOT_ERLANG_MK) $(APPS_HASH_FILE)
	@$(MAKE) -C $(ROOT) apps-makefile
	@if [ -s $(APPS_MK) ]; then \
		ROOT=$(ROOT) APPS_MK="$(APPS_MK)" $(MAKE) -C $(APPS_DIR) all ;\
	fi

.PHONY:
apps-test: $(DOT_ERLANG_MK) $(APPS_HASH_FILE)
	@$(MAKE) -C $(ROOT) apps-makefile
	@if [ -s $(APPS_MK) ]; then \
		ROOT=$(ROOT) APPS_MK="$(APPS_MK)" $(MAKE) -C $(APPS_DIR) compile-test-direct ;\
	fi

$(APPS_HASH_FILE):
	@if [ -s $(APPS_MK) ]; then \
		ROOT="$(ROOT)" APPS_MK="$(APPS_MK)" MORE_APPS_MK="" DEPS_DIR="$(APPS_DIR)" $(MAKE) -f $(ROOT)/make/Makefile.apps fetch-deps ;\
	fi
	@touch .apps.mk.$(shell md5sum $(APPS_MK) | cut -d' ' -f1)

$(DOT_ERLANG_MK):
	@ROOT=$(ROOT) $(MAKE) -C $(ROOT) dot_erlang_mk

.PHONY: clean-deps clean-deps-hash
clean-deps: clean-deps-hash

clean-deps-hash:
	@$(if $(wildcard .deps.mk.*), rm .deps.mk.*)

ifneq ($(wildcard $(DEPS_RULES)),)
include $(DEPS_RULES)
endif

## COMPILE_MOAR can contain Makefile-specific targets (see CLEAN_MOAR, compile-test)
.PHONY: compile compile-direct compile-lean compile-timed
compile: deps apps $(TEST_DEPS) $(COMPILE_MOAR) ebin/$(PROJECT).app json depend $(BEAMS) $(DOCS_INDEX)
compile-direct: $(COMPILE_MOAR) ebin/$(PROJECT).app json $(BEAMS) $(DOCS_INDEX)

.PHONY: recompile
recompile: clean compile

compile-lean: ERLC_OPTS := $(filter-out +debug_info,$(ERLC_OPTS)) +deterministic
compile-lean: compile

compile-timed: ERLC_OPTS := +time $(ERLC_OPTS)
compile-timed: compile

ebin/$(PROJECT).app:
	@mkdir -p ebin/
	ERL_LIBS=$(ELIBS) erlc -v $(ERLC_OPTS) $(PA) $(APPS_PA) -o ebin/ $(SOURCES)
	@sed "s/{modules,[[:space:]]*\[\]}/{modules, \[$(MODULES)\]}/" src/$(PROJECT).app.src \
	| sed -e "s!{vsn,\([^}]*\)}!\{vsn,\"$(KZ_VERSION)\"}!" > $@

ebin/%.beam: src/%.erl
	ERL_LIBS=$(ELIBS) erlc -v $(ERLC_OPTS) $(PA) $(APPS_PA) -o ebin/ $<

ebin/%.beam: src/*/%.erl
	ERL_LIBS=$(ELIBS) erlc -v $(ERLC_OPTS) $(PA) $(APPS_PA) -o ebin/ $<

ebin/%.beam: test/%.erl
	ERL_LIBS=$(ELIBS) erlc -v $(ERLC_OPTS) $(PA) $(APPS_PA) -o ebin/ $<

.PHONY: depend
depend: $(DEPS_RULES) $(TEST_DEPS)

$(DEPS_RULES):
	@rm -f $(DEPS_RULES)
	@ERL_LIBS=$(ELIBS) erlc -v +makedep +'{makedep_output, standard_io}' $(PA) $(APPS_PA) -o ebin/ $(SOURCES) > $(DEPS_RULES)

.PHONY: app_src
app_src:
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/apps_of_app.escript -a $(APPS_DIR)/$(PROJECT)/src/$(PROJECT).app.src

.PHONY: json
json: JSON = $(shell find $(CWD) -name '*.json')
json:
	@$(ROOT)/scripts/format-json.py $(JSON)

.PHONY: compile-test compile-test-direct
compile-test: deps $(TEST_DEPS) compile-test-kz-deps compile-test-direct json

compile-test-direct: ERLC_OPTS := -DTEST $(filter-out +warn_missing_spec,$(ERLC_OPTS))
compile-test-direct: deps apps-test $(COMPILE_MOAR) test/$(PROJECT).app $(TEST_BEAMS)

$(TEST_DEPS):
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/calculate-dep-targets.escript $(ROOT) $(PROJECT) > $(TEST_DEPS)

ifeq ($(wildcard $(TEST_DEPS)),)
KZ_DEPS_TARGETS =
else
KZ_DEPS = $(filter kazoo%,$(shell cat $(TEST_DEPS)))
KZ_DEPS_TARGETS = $(strip $(subst kazoo,compile-test-core-kazoo,$(KZ_DEPS)))
endif

.PHONY: compile-test-kz-deps
ifeq ($(KZ_DEPS_TARGETS),)
compile-test-kz-deps:
else
compile-test-kz-deps: $(KZ_DEPS_TARGETS)

compile-test-core-%:
	@ROOT=$(ROOT) $(MAKE) compile-test-direct -C $(CORE_DIR)/$*
endif

test/$(PROJECT).app:
	@mkdir -p test/
	@mkdir -p ebin/
	ERL_LIBS=$(ELIBS) erlc -v +nowarn_missing_spec $(filter-out +warn_missing_specs,$(ERLC_OPTS)) $(TEST_PA) $(APPS_PA) -o ebin/ $(TEST_SOURCES)

	@sed "s/{modules,[[:space:]]*\[\]}/{modules,\[$(TEST_MODULES)\]}/" src/$(PROJECT).app.src > $@
	@sed "s/{modules,[[:space:]]*\[\]}/{modules,\[$(TEST_MODULES)\]}/" src/$(PROJECT).app.src > ebin/$(PROJECT).app

.PHONY: clean clean-test
clean: clean-test
	@$(if $(wildcard cover/*), rm -r cover)
	@$(if $(wildcard ebin/*), rm ebin/*)
	@$(if $(wildcard *crash.dump), rm *crash.dump)
	@$(if $(wildcard $(DEPS_RULES)), rm $(DEPS_RULES))
	@rm -rf .apps.mk* .deps.mk*

clean-test: $(CLEAN_MOAR)
	@$(if $(wildcard $(TEST_DEPS)), rm $(TEST_DEPS))
	@$(if $(wildcard test/$(PROJECT).app), rm test/$(PROJECT).app)

TEST_CONFIG=$(ROOT)/rel/config-test.ini

## Use this one when debugging
.PHONY: compile-test check-compile-test
test: compile-test
	KAZOO_CONFIG=$(TEST_CONFIG) ERL_LIBS=$(ELIBS) $(ROOT)/scripts/eunit_run.escript $(TEST_MODULE_NAMES)
test.%: compile-test-direct
	KAZOO_CONFIG=$(TEST_CONFIG) ERL_LIBS=$(ELIBS) $(ROOT)/scripts/eunit_run.escript $*

check-compile-test: $(COMPILE_MOAR) test/$(PROJECT).app

COVER_REPORT_DIR=cover

## Use this one when CI
.PHONY: eunit eunit-run
eunit: compile-test test/$(PROJECT).app eunit-run

eunit-run:
	KAZOO_CONFIG=$(TEST_CONFIG) ERL_LIBS=$(ELIBS) $(ROOT)/scripts/eunit_run.escript --with-cover \
		--cover-project-name $(PROJECT) --cover-report-dir $(COVER_REPORT_DIR) \
		$(TEST_MODULE_NAMES)

.PHONY: cover cover-report
cover: $(ROOT)/make/cover.mk
	COVER=1 $(MAKE) eunit

cover-report: $(ROOT)/make/core.mk $(ROOT)/make/cover.mk eunit
	COVER=1 CT_RUN=1 $(MAKE) -f $(ROOT)/make/core.mk -f $(ROOT)/make/cover.mk cover-report

$(ROOT)/make/cover.mk: $(ROOT)/make/core.mk
	wget 'https://raw.githubusercontent.com/ninenines/erlang.mk/master/plugins/cover.mk' -O $(ROOT)/make/cover.mk

$(ROOT)/make/core.mk:
	wget 'https://raw.githubusercontent.com/ninenines/erlang.mk/master/core/core.mk' -O $(ROOT)/make/core.mk

.PHONY: proper compile-proper eunit-run
proper: compile-proper eunit-run

compile-proper: ERLC_OPTS += -DPROPER
compile-proper: clean-test compile-test-direct

compile-perf: ERLC_OPTS += -pa $(DEPS_DIR)/horse/ebin -DPERF +'{parse_transform, horse_autoexport}'
compile-perf: clean-test compile-test-direct

PLT ?= $(ROOT)/.kazoo.plt
$(PLT):
	@$(MAKE) -C $(ROOT) build-plt

.PHONY: dialyze dialyze-hard dialyze-types
dialyze: TO_DIALYZE ?= $(abspath ebin)
dialyze: $(PLT)
	@echo ":: dialyzing"
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/check-dialyzer.escript $(PLT) $(TO_DIALYZE)

dialyze-hard: TO_DIALYZE ?= $(abspath ebin)
dialyze-hard: $(PLT)
	@echo ":: dialyzing"
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/check-dialyzer.escript $(PLT) --hard $(TO_DIALYZE)

dialyze-types: TO_DIALYZE ?= $(abspath ebin)
dialyze-types: $(PLT)
	@echo ":: dialyzing types"
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/check-dialyzer-types.escript $(PLT) $(TO_DIALYZE)

REBAR=$(DEPS_DIR)/.erlang.mk/rebar/rebar

.PHONY: xref fmt perf fixture_shell
xref: compile
xref: TO_XREF = ebin/  #FIXME: set TO_XREF to an app's dependencies' ebin/ directories
xref:
	@ERL_LIBS=$(ELIBS) $(REBAR) xref skip_deps=true -C $(ROOT)/make/xref.local.config

fmt: TO_FMT ?= $(shell find src include test -iname '*.erl' -or -iname '*.hrl' -or -iname '*.escript')

perf: compile-perf
	$(gen_verbose) @ERL_LIBS=$(ELIBS) erl -noshell  -pa $(DEPS_DIR)/horse/ebin -pa $(TEST_PA) \
		-eval 'horse:app_perf($(PROJECT)), init:stop().'

perf.%: compile-perf
	$(gen_verbose) @ERL_LIBS=$(ELIBS) erl -noshell  -pa $(DEPS_DIR)/horse/ebin -pa $(TEST_PA) \
		-eval "horse:mod_perf($*), init:stop()."

fixture_shell: ERL_CRASH_DUMP = "$(ROOT)/$(shell date +%s)_ecallmgr_erl_crash.dump"
fixture_shell: ERL_LIBS = "$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR):$(shell echo $(DEPS_DIR)/rabbitmq_erlang_client-*/deps)"
fixture_shell: NODE_NAME ?= fixturedb
fixture_shell:
	@ERL_CRASH_DUMP="$(ERL_CRASH_DUMP)" ERL_LIBS="$(ERL_LIBS)" KAZOO_CONFIG=$(ROOT)/rel/config-test.ini \
		erl -setcookie change_me -name '$(NODE_NAME)' -s reloader "$$@"

.PHONY: code_checks apps_of_app
code_checks: edoc
	@printf ":: Check for copyright year\n\n"
	@$(ROOT)/scripts/bump-copyright-year.py $(SOURCES)
	@printf "\n:: Check code\n\n"
	@$(ROOT)/scripts/code_checks.bash $(SOURCES)
	@printf "\n:: Check for raw JSON usage\n\n"
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/no_raw_json.escript $(SOURCES)
	@printf "\n:: Check for Erlang 21 new stacktrace syntax\n\n"
	@$(ROOT)/scripts/check-stacktrace.py $(SOURCES)
	@printf "\n:: Generating schemas\n\n"
	ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/generate-schemas.escript $(SOURCES)

.PHONY: edoc
edoc:
	@printf "\n:: Check for Edoc\n\n"
	@CHANGED_ERL="$(SOURCES_FULL_PATH)" $(ROOT)/scripts/edocify.escript
	@CHANGED="$(SOURCES_FULL_PATH)" $(ROOT)/scripts/state-of-edoc.escript

DOCS_INDEX ?= doc/dev.yml
docs_index: pr_template
	@ERL_LIBS="$(DEPS_DIR):$(CORE_DIR)" $(ROOT)/scripts/build-application-doc-index.escript $(ROOT) $(CURDIR)

$(DOCS_INDEX): pr_template
	@ERL_LIBS="$(DEPS_DIR):$(CORE_DIR)" $(ROOT)/scripts/build-application-doc-index.escript $(ROOT) $(CURDIR)

PR_TEMPLATE = .github/pull_request_template.md

.PHONY: pr-template clean-pr-template
pr-template: clean-pr-template $(PR_TEMPLATE)

clean-pr-template:
	@rm -f $(PR_TEMPLATE)

$(PR_TEMPLATE):
	@mkdir -p $(dir $(PR_TEMPLATE))
	@cp -a $(ROOT)/make/pull_request_template.md $(PR_TEMPLATE)

hank:
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/hank.escript $(wildcard src/*.[h|e]rl) $(wildcard src/*/*.[h|e]rl) $(wildcard include/*.hrl)

$(CORE_DIR)/kazoo_stdlib/ebin/kz_style.beam: $(CORE_DIR)/kazoo_stdlib/src/kz_style.erl
	@ERL_LIBS=$(ELIBS) erlc -v $(ERLC_OPTS) $(PA) $(APPS_PA) -o $(CORE_DIR)/kazoo_stdlib/ebin $(CORE_DIR)/kazoo_stdlib/src/kz_style.erl

elvis: $(CORE_DIR)/kazoo_stdlib/ebin/kz_style.beam
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/elvis --config $(ROOT)/make/elvis.config -k --parallel auto rock $(subst $(ROOT)/,,$(filter %.erl,$(wildcard $(TEST_SOURCES))))

splchk-all: $(addsuffix .common,$(basename $(SOURCES)) $(basename $(JSON)) $(basename $(DOCS_INDEX)) $(basename $(DOCS)) )

include $(ROOT)/make/splchk.mk
include $(ROOT)/make/fmt.mk
