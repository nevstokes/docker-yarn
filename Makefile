REPO = $(shell git config --get remote.origin.url)
BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
COMMIT = $(shell git rev-parse --short HEAD)
DATE = $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

.DEFAULT_GOAL := help
.PHONY: build build_all build_latest build_lts help release

help: ## Displays list and descriptions of available targets
	@awk -F ':|\#\#' '/^[^\t].+:.*\#\#/ {printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF }' $(MAKEFILE_LIST) | sort

build:
	@docker build \
		--build-arg VCS_URL=$(REPO) \
		--build-arg VCS_REF=$(COMMIT) \
		--build-arg BUILD_DATE=$(DATE) \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		-t nevstokes/yarn:$(TAG) .

build_all: build_latest build_lts ## Build both latest and LTS versions of Node

build_latest: ## Build latest version of Node
	@$(MAKE) release RELEASE_INDEX=1 TAG=latest

build_lts: ## Build LTS version of Node
	@$(MAKE) release RELEASE_INDEX=2  TAG=lts

release:
	@$(MAKE) build NODE_VERSION=$(shell wget -q https://github.com/nodejs/node/releases.atom -O - | xsltproc --stringparam version_index $(RELEASE_INDEX) yarn-version.xsl - | sed -E 's/\/nodejs\/node\/releases\/tag\/v([0-9.]+)/\1/')
