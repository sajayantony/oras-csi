DRIVER_VERSION ?= 0.1.0
DEVTAG=$(DRIVER_VERSION)-dev

NAME=oras-csi-plugin
DOCKER_REGISTRY=ghcr.io/converged-computing

.PHONY: help
help: ## Generates help for all targets
	@grep -E '^[^#[:space:]].*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

ready: clean compile ## Clean pods and compiles the driver
publish-dev: clean compile build-dev push-dev
redo: uninstall compile build push install

uninstall: ## Unisntalls the plugin from the cluster
	@echo "==> Uninstalling plugin"
	kubectl delete -f deploy/kubernetes/csi-oras.yaml || true 
	kubectl delete -f deploy/kubernetes/csi-oras-config.yaml || true

install: ## Install plugin into the cluster
	@echo "==> Installing plugin"
	kubectl apply -f deploy/kubernetes/csi-oras.yaml || true
	kubectl apply -f deploy/kubernetes/csi-oras-config.yaml || true

compile:
	@echo "==> Building the project"
	@env CGO_ENABLED=0 GOCACHE=/tmp/go-cache GOOS=linux GOARCH=amd64 go build -a -o cmd/oras-csi-plugin/${NAME} cmd/oras-csi-plugin/main.go

build:  ## Build docker images for the csi-driver
	@echo "==> Building DEV docker images"
	@docker build -t $(DOCKER_REGISTRY)/oras-csi-plugin:$(DEVTAG) cmd/oras-csi-plugin
	@docker build -t $(DOCKER_REGISTRY)/oras-csi-plugin:latest cmd/oras-csi-plugin

push: ## Push docker images to the registry
	@echo "==> Publishing DEV $(DOCKER_REGISTRY)/oras-csi-plugin:$(DEVTAG)"
	@docker push $(DOCKER_REGISTRY)/oras-csi-plugin:$(DEVTAG)
	@docker push $(DOCKER_REGISTRY)/oras-csi-plugin:latest
	@echo "==> Your DEV image is now available at $(DOCKER_REGISTRY)/oras-csi-plugin:$(DEVTAG)"


clean: ## Deletes driver and all pods
	@echo "==> Cleaning releases"
	@GOOS=linux go clean -i -x ./...
	kubectl delete -f deploy/kubernetes/csi-oras.yaml || true 
	kubectl delete -f deploy/kubernetes/csi-oras-config.yaml || true
	kubectl delete --force pods --all

.PHONY: clean