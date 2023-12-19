geas-changed:
	ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/check-geas.escript -a $(CHANGED_ERL)

geas:
	ERL_LIBS=$(DEPS_DIR):$(CORE_DIR):$(APPS_DIR) $(ROOT)/scripts/check-geas.escript $(CORE_DIR)/* $(APPS_DIR)/*
