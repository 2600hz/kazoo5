# Targets for interacting with the ELP CLI

ELP_PROJECT_JSON = $(ROOT)/.elp/project.json
ELP ?= elp

.PHONY: eq-app
eq-app:
	$(ELP) eqwalize-app $(PROJECT) --project $(ELP_PROJECT_JSON)

# per module eqwalize
eq-%:
	$(ELP) eqwalize $* --project $(ELP_PROJECT_JSON)
