#!/usr/bin/make

IN_DOCKER := docker compose run --rm --user "$(shell id -u):$(shell id -g)" shell
.DELETE_ON_ERROR: # delete target file if the command fails
.FORCE: # dummy target to force execution
.DEFAULT_GOAL = help # default target to display help

help: ## Display a list of available commands with descriptions
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# --- DOCKER ----------------------------------------------------------------------------------------------------------

shell: ## Start a shell session in a Docker container with the current directory mounted
	docker compose run --rm --user "$(shell id -u):$(shell id -g)" shell sh

# --- CODE GENERATION -------------------------------------------------------------------------------------------------

.kube/config: ## Generate a kube config file with cluster credentials
	@test -d ./.kube || mkdir -m 700 ./.kube # create a directory with minimal permissions
	@test -f ./.kube/config && rm -f ./.kube/config || true # due to file permissions remove existing file first
	$(IN_DOCKER) doppler secrets get --plain KUBE_CONFIG > ./.kube/config # fetch the kube config from the Doppler secret
	@chmod 400 ./.kube/config # set minimal file permissions

helm/%/values.yaml: .FORCE ## Generate a chart values.yaml file with secrets for the specified directory
	$(IN_DOCKER) doppler secrets substitute ./helm/$*/values.doppler.yaml > ./helm/$*/values.yaml
	@chmod 600 ./helm/$*/values.yaml

helm/%/charts: ## Download and install Helm chart dependencies for the specified directory
	$(IN_DOCKER) helm dependency update ./helm/$*/ 1>/dev/null
	@test -d ./helm/$*/charts || mkdir -p ./helm/$*/charts # create an empty directory even if no deps installed

dump.%.yaml: helm/%/charts helm/%/values.yaml ## Render the specified Helm chart into a YAML dump file
	$(IN_DOCKER) helm template ./helm/$* > ./dump.$*.yaml

# --- LINTING & DEBUGGING ---------------------------------------------------------------------------------------------

dump: dump.system.yaml dump.monitoring.yaml dump.apps.yaml ## Render all Helm charts into YAML dump files

lint-chart-%: helm/%/values.yaml helm/%/charts ## Perform linting on the Helm chart in the specified directory
	$(IN_DOCKER) helm lint --quiet --strict ./helm/$*
	$(IN_DOCKER) kube-linter --with-color lint ./helm/$*

lint-system: lint-chart-system              ## Lint the system Helm chart
lint-monitoring: lint-chart-monitoring      ## Lint the monitoring Helm chart
lint-apps: lint-chart-apps                  ## Lint the apps Helm chart
lint: lint-system lint-monitoring lint-apps ## Perform linting on all charts

# --- DEPLOYMENT ------------------------------------------------------------------------------------------------------

install-chart-%: .kube/config helm/%/values.yaml helm/%/charts ## Install the specified Helm chart
	$(IN_DOCKER) helm install --rollback-on-failure --create-namespace --namespace $* $* ./helm/$*

install-system: lint-system install-chart-system             ## Install the system components Helm chart
install-monitoring: lint-monitoring install-chart-monitoring ## Install the monitoring components Helm chart
install-apps: lint-apps install-chart-apps                   ## Install the applications Helm chart
install: install-system install-monitoring install-apps      ## Install all Helm charts

upgrade-chart-%: .kube/config helm/%/values.yaml helm/%/charts ## Upgrade the specified Helm chart
	$(IN_DOCKER) helm upgrade --rollback-on-failure --namespace $* $* ./helm/$*

upgrade-system: lint-system upgrade-chart-system             ## Upgrade the system components Helm chart
upgrade-monitoring: lint-monitoring upgrade-chart-monitoring ## Upgrade the monitoring components Helm chart
upgrade-apps: lint-apps upgrade-chart-apps                   ## Upgrade the applications Helm chart
upgrade: upgrade-system upgrade-monitoring upgrade-apps      ## Upgrade all Helm charts
