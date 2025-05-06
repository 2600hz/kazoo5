# https://arxiv.org/pdf/2107.08699.pdf
DEPS =  rebar3_hank \
	katana_code

dep_rebar3_hank = hex 1.1.1
dep_katana_code = hex 2.2.0

HANK_DEP_DIR = $(DEPS_DIR)/rebar3_hank

hank: $(HANK_DEP_DIR)
	ERL_LIBS=$(ROOT)/deps:$(ROOT)/core:$(APPS_DIR) $(ROOT)/scripts/hank.escript

hank-changed: $(HANK_DEP_DIR)
	ERL_LIBS=$(ROOT)/deps:$(ROOT)/core:$(APPS_DIR) $(ROOT)/scripts/hank.escript $(CHANGED)

$(HANK_DEP_DIR):
	ROOT=$(ROOT) DEPS_MK="$(ROOT)/make/hank.mk" $(MAKE) -C $(DEPS_DIR)/ all
