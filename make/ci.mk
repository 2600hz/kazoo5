PIP := $(shell { command -v pip; } 2>/dev/null)
CI_DIR := $(CURDIR)/make
CI_VALIDATOR := $(CI_DIR)/circleci
CI_CONFIG := $(CURDIR)/.circleci/config.yml

.PHONY: ci
ci: ci-config ci-steps

.PHONY: ci-update
ci-update: $(CI_VALIDATOR)
	$(CI_VALIDATOR) update

.PHONY: ci-config
ci-config: $(CI_VALIDATOR)
	@$(CI_VALIDATOR) config validate -c $(CI_CONFIG) || (echo "$(CI_CONFIG):1:"; exit 1)

# | $(CI_DIR): see https://www.gnu.org/software/make/manual/make.html#Prerequisite-Types
# order-only-prereq
# otherwise cURL will be run everytime
$(CI_VALIDATOR): | $(CI_DIR)
	@curl -fLSs https://circle.ci/cli | DESTDIR="$(CI_DIR)" bash

$(CI_DIR):
	@mkdir $(CI_DIR)

.PHONY: ci-steps
ci-steps: ci-pre ci-fmt ci-build ci-codechecks ci-docs ci-schemas ci-dialyze ci-git ci-release
	@$(ROOT)/scripts/check-unstaged.bash

.PHONY: ci-pre
ci-pre:
ifneq ($(PIP),)
## needs root access
	@echo $(CHANGED)
	@$(PIP) install --user --upgrade pip
	@$(PIP) install --user PyYAML mkdocs pyembed-markdown jsonschema
else
	$(error "pip is not available, please install python3-pip package")
endif

.PHONY: ci-docs
ci-docs:
	@./scripts/state-of-docs.py || true
	@CHANGED="$(CHANGED_ERL)" $(ROOT)/scripts/state-of-edoc.escript
	@$(MAKE) apis
	@$(MAKE) docs

.PHONY: ci-codechecks
ci-codechecks: elvis
	@./scripts/code_checks.bash $(CHANGED)
	@$(MAKE) code_checks
	@$(MAKE) app_applications
	@$(MAKE) validate-js

.PHONY: ci-fmt
ci-fmt:
	@$(MAKE) fmt
	@$(MAKE) elvis

.PHONY: ci-build
ci-build:
	@$(MAKE) clean clean-deps deps kazoo xref sup_completion

.PHONY: ci-schemas
ci-schemas:
	@$(MAKE) validate-schemas
	@$(if $(CHANGED_SWAGGER), $(MAKE) ci-swagger)

.PHONY: ci-swagger
ci-swagger:
	@-$(MAKE) validate-swagger

.PHONY: ci-unstaged
ci-unstaged:
	@$(ROOT)/scripts/check-unstaged.bash

.PHONY: ci-dialyze
ci-dialyze: build-plt
ci-dialyze:
	@TO_DIALYZE="$(CHANGED)" $(MAKE) dialyze-it
	@TO_DIALYZE="$(CHANGED)" $(MAKE) dialyze-types

.PHONY: ci-release
ci-release:
	@$(MAKE) build-ci-release

.PHONY: ci-git
ci-git:
	@$(ROOT)/scripts/check-unstaged.bash
	@$(ROOT)/kgit git --no-pager diff --staged
	@$(ROOT)/scripts/check-git-diff-untracked.bash "$(ROOT)" "$(ROOT)/core" "$(ROOT)/applications/*"
