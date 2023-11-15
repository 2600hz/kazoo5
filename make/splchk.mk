.PHONY = splchk splchk-docs splchk-changed splchk-json splchk-code

KAZOO_DICT = .aspell.en.pws
KAZOO_REPL = .aspell.en.prepl

ASPELL = aspell $(ASPELL_ARGS) --home-dir=$(ROOT) --personal=$(KAZOO_DICT) --repl=$(KAZOO_REPL) --lang=en -x check

$(ROOT)/$(KAZOO_DICT):
	@$(file >$(ROOT)/$(KAZOO_DICT),personal_ws-1.1 en 0 utf-8)

$(ROOT)/$(KAZOO_REPL):
	@$(file >$(ROOT)/$(KAZOO_REPL),personal_repl-1.1 en 0 utf-8)

splchk-init: $(ROOT)/$(KAZOO_DICT) $(ROOT)/$(KAZOO_REPL)

splchk: splchk-changed

ifeq ($(wildcard $(CURDIR)/doc/*.md),)
splchk-docs:: splchk-init
else
DOCS := $(shell find doc -type f -name "*.md" -o -regex "doc/mkdocs/.+" -prune)
splchk-docs:: splchk-init $(addsuffix .chk,$(DOCS))
endif

ifneq ($(wildcard $(CURDIR)/priv/templates/*),)
TEMPLATES := $(shell find $(CURDIR)/priv/templates -type f)
splchk-docs:: splchk-init $(addsuffix .chk,$(TEMPLATES))
endif

ifneq ($(wildcard $(CURDIR)/test/rendered-templates/*),)
RENDERED_TEMPLATES := $(shell find $(CURDIR)/test/rendered-templates -type f)
splchk-docs:: splchk-init $(addsuffix .chk,$(RENDERED_TEMPLATES))
endif

ifneq ($(wildcard $(CURDIR)/priv/*/templates/*),)
TEMPLATES := $(shell find $(CURDIR)/priv/*/templates/ -type f)
splchk-docs:: splchk-init $(addsuffix .chk,$(TEMPLATES))
endif

JSON := $(wildcard $(CURDIR)/priv/couchdb/schemas/*.json)
ifeq ($(JSON),)
splchk-json: splchk-init
else
splchk-json: splchk-init $(addsuffix .chk,$(JSON))
endif

ESCRIPTS := $(wildcard $(CURDIR)/scripts/*.escript)
SRC := $(wildcard $(CURDIR)/src/*.*rl) $(wildcard $(CURDIR)/src/*/*.erl) $(wildcard $(CURDIR)/include/*.hrl)
CODE := $(SRC) $(ESCRIPTS)
ifeq ($(CODE),)
splchk-code: splchk-init
else
splchk-code: splchk-init $(addsuffix .chk,$(CODE))
endif

.PHONY: splchk-changed
splchk-changed: splchk-init $(addsuffix .chk,$(wildcard $(CHANGED)))

.PHONY: splchk-common
splchk-common: $(addsuffix .common,$(wildcard $(CHANGED_ERL) $(CHANGED_JSON) $(CHANGED_YML) $(CHANGED_DOCS)))

%.common: %
	@$(ROOT)/scripts/check-spelling.bash $<

%.chk: TO_CHK = $(basename $@)

# Basic checks for these file types
CHK_PATTERNS = $(foreach p,md json text txt org tmpl,%.$(p).chk)
# Checks for Erlang types
ERL_CHK_PATTERNS = $(foreach p,erl escript hrl,%.$(p).chk)
# Checks for HTML
HTML_CHK_PATTERNS = %.html.chk

$(CHK_PATTERNS) $(ERL_CHK_PATTERNS) $(HTML_CHK_PATTERNS):
	@$(ASPELL) $(TO_CHK)

$(ERL_CHK_PATTERNS): ASPELL_ARGS += --add-filter-path=$(ROOT) --mode=erlang
$(HTML_CHK_PATTERNS): ASPELL_ARGS += --add-filter-path=$(ROOT) --mode=html

Makefile.chk: ASPELL_ARGS += --add-filter-path=$(ROOT)
Makefile.chk:
	@$(ASPELL) $(TO_CHK)
