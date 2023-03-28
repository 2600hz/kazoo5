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

.PHONY: kazoo-code-workspace
kazoo-code-workspace: $(KZ_VSCODE) $(KZ_VSCODE_DEBUGGER)

$(KZ_VSCODE):
	@touch $(KZ_VSCODE)
	@echo '{"folders": [' > $(KZ_VSCODE)
	@for app in $(APPS) ; do echo "{ \"name\": \"kapp/$$(basename $${app})\", \"path\": \"applications/$$(basename $${app})\" }," >> $(KZ_VSCODE); done
	@echo '{"name": "core", "path": "core" },' >> $(KZ_VSCODE)
	@echo '{"name": "kazoo (root)", "path": "." }],' >> $(KZ_VSCODE)
	@echo '"settings": {"files.exclude": {"/applications/": true,"/core/": true}' >> $(KZ_VSCODE)
	@echo '}}' >> $(KZ_VSCODE)
	@$(ROOT)/scripts/format-json.py $(KZ_VSCODE)
	@echo "generated $(KZ_VSCODE)"

$(KZ_VSCODE_DEBUGGER):
	@mkdir $(ROOT)/.vscode
	@cp $(ROOT)/.vscode_launch.json $(ROOT)/.vscode/launch.json
	@echo "generated $(KZ_VSCODE_DEBUGGER)"
