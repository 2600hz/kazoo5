.PHONY: erlang-ls
erlang-ls: $(ERLANG_LS) copy-erlang-ls

$(ERLANG_LS):
	@touch $(ERLANG_LS)
	@echo "plt_path: $(PLT)" >> $(ERLANG_LS)
	@echo "apps_dirs: " >> $(ERLANG_LS)
	@echo "    - $(ROOT)/core/*" >> $(ERLANG_LS)
	@echo "    - $(ROOT)/applications/*" >> $(ERLANG_LS)
	@echo "deps_dirs: " >> $(ERLANG_LS)
	@echo "    - $(ROOT)/deps/*" >> $(ERLANG_LS)
	@echo "include_dirs: " >> $(ERLANG_LS)
	@echo "    - $(ROOT)/deps" >> $(ERLANG_LS)
	@echo "    - $(ROOT)/core" >> $(ERLANG_LS)
	@echo "    - $(ROOT)/applications" >> $(ERLANG_LS)
	@echo "    - $(ROOT)/deps/*/include" >> $(ERLANG_LS)
	@echo "    - $(ROOT)/deps/*/src" >> $(ERLANG_LS)
	@echo "    - $(ROOT)/core/*/include" >> $(ERLANG_LS)
	@echo "    - $(ROOT)/core/*/src" >> $(ERLANG_LS)
	@echo "    - $(ROOT)/applications/*/include" >> $(ERLANG_LS)
	@echo "    - $(ROOT)/applications/*/src" >> $(ERLANG_LS)
	@echo "runtime: " >> $(ERLANG_LS)
	@echo "    use_long_names: true" >> $(ERLANG_LS)
	@echo "generated $(ERLANG_LS)"

.PHONY: copy-erlang-ls
copy-erlang-ls:
	@for app in $(APPS); do cp $(ERLANG_LS) "applications/$$(basename $${app})/"; done
	@cp $(ERLANG_LS) "core/"
	@echo "copied $(ERLANG_LS) to core and all apps"
	@echo
	@echo "It is highly recommended to copy $(ERLANG_LS) file to your global Erlang-LS configuration place"
	@echo "This could be your home directory or ~/.config/erlang_ls directory"

.PHONY: clean-erlang-ls
clean-erlang-ls:
	@rm $(ERLANG_LS)

ELP_DIR = $(ROOT)/.elp
ELP_PROJECT_JSON = $(ELP_DIR)/project.json
ELP_BUILD_JSON = $(ELP_DIR)/build_info.json
ELP_TOML = $(ROOT)/.elp.toml
ELP ?= elp

.PHONY: elp clean-elp elp-lint
elp: deps fetch-core fetch-apps $(ELP_PROJECT_JSON) $(ELP_BUILD_JSON) $(ELP_TOML)

clean-elp:
	@rm -f $(ELP_PROJECT_JSON) $(ELP_BUILD_JSON) $(ELP_TOML)

$(ELP_PROJECT_JSON):
	@mkdir -p $(ELP_DIR)
	ERL_LIBS=$(ROOT)/deps:$(ROOT)/core $(ROOT)/scripts/elp.escript $(ROOT) $@

$(ELP_BUILD_JSON):
	$(ELP) build-info --project $(ELP_PROJECT_JSON) --json --to $(ELP_BUILD_JSON)

$(ELP_TOML):
	printf "[build_info]\nfile = \"$(ELP_BUILD_JSON)\"\n" > $(@)

elp-lint:
	$(ELP) --project $(ELP_PROJECT_JSON) lint


.PHONY: kazoo-code-workspace
kazoo-code-workspace: $(KZ_VSCODE) $(KZ_VSCODE_DEBUGGER) $(KZ_VSCODE_SETTINGS)

$(KZ_VSCODE): $(APPS_HASH_FILE)
	@touch $(KZ_VSCODE)
	@echo '{"folders": [' > $(KZ_VSCODE)
	@for app in $(APPS) ; do echo "{ \"name\": \"kapp/$$(basename $${app})\", \"path\": \"applications/$$(basename $${app})\" }," >> $(KZ_VSCODE); done
	@echo '{"name": "core", "path": "core" },' >> $(KZ_VSCODE)
	@echo '{"name": "kazoo (root)", "path": "." }]' >> $(KZ_VSCODE)
	@echo '}' >> ${KZ_VSCODE}
	@$(ROOT)/scripts/format-json.py $(KZ_VSCODE)
	@echo "generated $(KZ_VSCODE)"

$(KZ_VSCODE_DEBUGGER): $(KZ_VSCODE_DIR)
	@cp $(ROOT)/.vscode_launch.json $(KZ_VSCODE_DEBUGGER)
	@echo "generated $(KZ_VSCODE_DEBUGGER)"

$(KZ_VSCODE_SETTINGS): $(KZ_VSCODE_DIR)
	@cp $(ROOT)/.vscode_settings.json $(KZ_VSCODE_SETTINGS)
	@echo "generated $(KZ_VSCODE_SETTINGS)"

$(KZ_VSCODE_DIR):
	@mkdir $(KZ_VSCODE_DIR)
