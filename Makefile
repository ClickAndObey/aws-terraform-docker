all: clean lint

MAJOR_VERSION := 1
MINOR_VERSION := 0
BUILD_VERSION ?= $(USER)
VERSION := $(MAJOR_VERSION).$(MINOR_VERSION).$(BUILD_VERSION)

ORGANIZATION := clickandobey
SERVICE_NAME := aws-terraform-docker

DOCKER_IMAGE_NAME := ${ORGANIZATION}-${SERVICE_NAME}
GITHUB_REPO := "ghcr.io"
DOCKER_REPO_IMAGE_NAME := ${GITHUB_REPO}/${ORGANIZATION}/${SERVICE_NAME}:${VERSION}

ifneq ($(GITHUB_ACTION),)
  INTERACTIVE=--env "INTERACTIVE=None"
else
  INTERACTIVE=--interactive
endif

# Docker

build-docker: docker/Dockerfile src/main/scripts/run_terraform
	@docker build \
		-t ${DOCKER_IMAGE_NAME} \
		-f docker/Dockerfile \
		.
	@touch build-docker

# Terraform

dev-terraform-plan: build-docker
	@docker run \
		--rm \
		${INTERACTIVE} \
		--env ENVIRONMENT=dev \
		--env TERRAFORM_DIRECTORY=/terraform \
		--env REGION=us-west-2 \
		--env SERVICE_NAME=${SERVICE_NAME} \
		-v `pwd`/terraform:/terraform \
		-v `pwd`/src/main/scripts:/scripts \
		-v $(HOME)/.aws:/root/.aws \
		${DOCKER_IMAGE_NAME} \
			plan

# Release

release: build-docker github-docker-login
	@echo Tagging webservice image to ${DOCKER_REPO_IMAGE_NAME}...
	@docker tag ${DOCKER_IMAGE_NAME} ${DOCKER_REPO_IMAGE_NAME}
	@echo Pushing webservice docker image to ${DOCKER_REPO_IMAGE_NAME}...
	@docker push ${DOCKER_REPO_IMAGE_NAME}

# Linting

lint: lint-markdown lint-terraform

lint-markdown:
	@echo Linting markdown files...
	@docker run \
		--rm \
		-v `pwd`:/workspace \
		wpengine/mdl \
			/workspace
	@echo Markdown linting complete.

lint-terraform: build-docker
	@docker run \
		--rm \
		${INTERACTIVE} \
		--env ENVIRONMENT=dev \
		--env TERRAFORM_DIRECTORY=/terraform \
		--env REGION=us-west-2 \
		--env SERVICE_NAME=${SERVICE_NAME} \
		-v `pwd`/terraform:/terraform \
		-v `pwd`/src/main/scripts:/scripts \
		-v $(HOME)/.aws:/root/.aws \
		${DOCKER_IMAGE_NAME} \
			fmt -check=true -diff=true

# Utilities

clean:
	@echo Removing Make Target Files...
	@rm -f build-docker
	@echo Make Target Files Removed.

github-docker-login:
	@echo ${CR_PAT} | docker login ${GITHUB_REPO} -u ${GITHUB_USER} --password-stdin