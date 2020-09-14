FMT = $(DEPS_DIR)/erlfmt/erlfmt
#FMT = $(ROOT)/make/erlang-formatter/fmt.sh
# v1.11.0
#FMT_SHA = c8adcbc8c3c7fedecc3621c399a1fd7afce7c9ee

.PHONY: fmt fmt-all fmt-views fmt-views-all clean-fmt clean-$(FMT)

$(FMT):
	@ROOT=$(ROOT) $(MAKE) $(DEPS_DIR)/Makefile
	@ROOT=$(ROOT) DEPS_MK=$(ROOT)/make/deps.fmt.mk $(MAKE) -C $(DEPS_DIR)/
	@ERLANG_MK_FILENAME=$(ROOT)/erlang.mk $(MAKE) -C $(DEPS_DIR)/erlfmt escript

fmt-all: $(FMT)
	@ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(FMT) -w $(shell find core applications scripts -name "*.erl" -or -name "*.hrl" -or -name "*.escript")

fmt: TO_FMT ?= $(CHANGED_ERL)
fmt: $(FMT)
	@$(if $(TO_FMT), ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(FMT) -w $(TO_FMT))

fmt-views-all:
	@$(ROOT)/scripts/format-couchdb-views.py $(shell find core/kazoo_apps/priv/couchdb/account -name '*.json')
	@$(ROOT)/scripts/format-couchdb-views.py $(shell find applications core -wholename '*/couchdb/views/*.json')

fmt-views: TO_FMT_VIEWS ?= $(shell git --no-pager diff --name-only HEAD $(BASE_BRANCH) -- "*/couchdb/views/*.json" "*/couchdb/account/*.json")
fmt-views:
	@$(if $(TO_FMT_VIEWS), @$(ROOT)/scripts/format-couchdb-views.py $(TO_FMT_VIEWS))

clean-fmt: clean-$(FMT)

clean: clean-$(FMT)

clean-$(FMT):
	$(if $(wildcard $(FMT)), rm -r $(dir $(FMT)))
