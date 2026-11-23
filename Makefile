SHELL := bash
.SHELLFLAGS := -euo pipefail -c

TF_DIR     := terraform/envs/prod
BUILD      := $(abspath .build)
CLUSTER    := fieldnote-prod
REGION     := us-east-1
KUBECONFIG := $(BUILD)/kubeconfig
HELM       := helm --kubeconfig $(KUBECONFIG)
HELM_FLAGS := --create-namespace --rollback-on-failure --timeout 10m

.PHONY: plan apply kubeconfig deploy deploy-api deploy-web

$(BUILD):
	mkdir -p $@

plan: | $(BUILD)
	terraform -chdir=$(TF_DIR) init -input=false
	terraform -chdir=$(TF_DIR) plan -input=false -out=$(BUILD)/tfplan

apply:
	terraform -chdir=$(TF_DIR) apply -input=false $(BUILD)/tfplan

kubeconfig: | $(BUILD)
	aws eks update-kubeconfig --name $(CLUSTER) --region $(REGION) --kubeconfig $(KUBECONFIG)

deploy: deploy-api deploy-web

deploy-api: kubeconfig
	terraform -chdir=$(TF_DIR) output -raw api_helm_values > $(BUILD)/api-infra.yaml
	$(HELM) upgrade --install api charts/api -n api $(HELM_FLAGS) \
	  -f charts/api/values-prod.yaml -f $(BUILD)/api-infra.yaml

deploy-web: kubeconfig
	$(HELM) upgrade --install web charts/web -n web $(HELM_FLAGS) \
	  -f charts/web/values-prod.yaml
