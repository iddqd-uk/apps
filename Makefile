#!/usr/bin/make

DOPPLER_ARGS = --no-check-version --project iddqd-uk --config helm # global Doppler arguments

.DELETE_ON_ERROR: # delete target file if the command fails
.FORCE: # dummy target to force execution
.DEFAULT_GOAL = help # default target to display help

help: ## Display a list of available commands with descriptions
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# --- CODE GENERATION -------------------------------------------------------------------------------------------------

kubeconfig.yaml: ## Generate a kubeconfig.yaml file with cluster credentials
	@test -f ./kubeconfig.yaml && rm -f ./kubeconfig.yaml || true # due to file permissions remove existing file first
	doppler $(DOPPLER_ARGS) secrets get --plain KUBE_CONFIG > ./kubeconfig.yaml
	@chmod 400 ./kubeconfig.yaml # set minimal file permissions

helm/%/values.yaml: .FORCE ## Generate a chart values.yaml file with secrets for the specified directory
	doppler $(DOPPLER_ARGS) secrets substitute ./helm/$*/values.doppler.yaml > ./helm/$*/values.yaml
	@chmod 600 ./helm/$*/values.yaml

helm/%/charts: ## Download and install Helm chart dependencies for the specified directory
	helm dependency update ./helm/$*/ 1>/dev/null
	@test ! -d ./helm/$*/charts && mkdir -p ./helm/$*/charts # create an empty directory even if no dependencies installed

dump.%.yaml: helm/%/charts helm/%/values.yaml ## Render the specified Helm chart into a YAML dump file
	helm template ./helm/$* > ./dump.$*.yaml

# --- LINTING & DEBUGGING ---------------------------------------------------------------------------------------------

dump: dump.system.yaml dump.apps.yaml ## Render all Helm charts into YAML dump files

lint-chart-%: helm/%/values.yaml helm/%/charts ## Perform linting on the Helm chart in the specified directory
	helm lint --quiet --strict ./helm/$*
	docker run --rm -t -v "$(shell pwd):/src:ro" -w "/src" ghcr.io/stackrox/kube-linter --with-color lint ./helm/$*

lint-system: lint-chart-system ## Lint the system Helm chart
lint-apps: lint-chart-apps     ## Lint the apps Helm chart
lint: lint-system lint-apps    ## Perform linting on all charts

git-leaks: ## Scan the repository for secrets using gitleaks
	docker run --rm -t -v "$(shell pwd):/src:ro" ghcr.io/gitleaks/gitleaks detect --no-banner --source /src

# --- DEPLOYMENT ------------------------------------------------------------------------------------------------------

install-chart-%: kubeconfig.yaml helm/%/values.yaml helm/%/charts ## Install the specified Helm chart
	helm install --kubeconfig ./kubeconfig.yaml --atomic $* ./helm/$*

install-system: lint-system install-chart-system ## Install the system components Helm chart
install-apps: lint-apps install-chart-apps       ## Install the applications Helm chart
install: install-system install-apps             ## Install all Helm charts (system and applications)

upgrade-chart-%: kubeconfig.yaml helm/%/values.yaml helm/%/charts ## Upgrade the specified Helm chart
	helm upgrade --kubeconfig ./kubeconfig.yaml --atomic $* ./helm/$*

upgrade-system: lint-system upgrade-chart-system ## Upgrade the system components Helm chart
upgrade-apps: lint-apps upgrade-chart-apps       ## Upgrade the applications Helm chart
upgrade: upgrade-system upgrade-apps             ## Upgrade all Helm charts (system and applications)
