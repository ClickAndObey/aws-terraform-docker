all: clean lint

MAJOR_VERSION := 1
MINOR_VERSION := 0
BUILD_VERSION ?= $(USER)
VERSION := $(MAJOR_VERSION).$(MINOR_VERSION).$(BUILD_VERSION)
MAJOR_DOT_MINOR_VERSION := $(shell echo $$(echo ${VERSION} | cut -d. -f1).$$(echo ${VERSION} | cut -d. -f2))

ORGANIZATION := clickandobey
SERVICE_NAME := terraform-shared

DOCKER_IMAGE_NAME := ${ORGANIZATION}-${SERVICE_NAME}
GITHUB_REPO := "ghcr.io"
DOCKER_REPO_IMAGE_NAME := ${GITHUB_REPO}/${ORGANIZATION}/${SERVICE_NAME}:${VERSION}
MAJOR_DOT_MINOR_VERSION_DOCKER_REPO_IMAGE_NAME := ${GITHUB_REPO}/${ORGANIZATION}/{SERVICE_NAME}:${MAJOR_DOT_MINOR_VERSION}
LATEST_DOCKER_REPO_IMAGE_NAME := ${GITHUB_REPO}/${ORGANIZATION}/${SERVICE_NAME}:latest

ROOT_DIRECTORY := `pwd`
SCRIPTS_DIRECTORY := ${ROOT_DIRECTORY}/src/main/scripts
LOCAL_SCRIPTS_DIRECTORY := ${SCRIPTS_DIRECTORY}/local
TERRAFORM_SHARED_DIRECTORY := ${ROOT_DIRECTORY}/.terraform-shared

ifneq ($(GITHUB_ACTION),)
  INTERACTIVE=--env "INTERACTIVE=None"
else
  INTERACTIVE=--interactive
endif

# Docker

build-docker: docker/Dockerfile src/main/scripts/docker/run_terraform
	@docker build \
		-t ${DOCKER_IMAGE_NAME} \
		-f docker/Dockerfile \
		.
	@touch build-docker

# Terraform

terraform-plan-staging: build-docker .terraform-shared
	@export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}; \
	`pwd`/src/main/scripts/local/run_terraform \
		plan \
		us-east-1 \
		staging

terraform-apply-staging: build-docker .terraform-shared
	@export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}; \
	${TERRAFORM_SHARED_DIRECTORY}/run_terraform \
		apply \
		us-east-1 \
		staging

terraform-plan-preproduction: build-docker .terraform-shared
	@export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}; \
	${TERRAFORM_SHARED_DIRECTORY}/run_terraform \
		plan \
		us-east-1 \
		preproduction

terraform-apply-preproduction: build-docker .terraform-shared
	@export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}; \
	${TERRAFORM_SHARED_DIRECTORY}/run_terraform \
		apply \
		us-east-1 \
		preproduction

terraform-plan-uat: build-docker .terraform-shared
	@export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}; \
	${TERRAFORM_SHARED_DIRECTORY}/run_terraform \
		plan \
		us-east-1 \
		uat

terraform-apply-uat: build-docker .terraform-shared
	@export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}; \
	${TERRAFORM_SHARED_DIRECTORY}/run_terraform \
		apply \
		us-east-1 \
		uat

terraform-plan-production: build-docker .terraform-shared
	@export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}; \
	${TERRAFORM_SHARED_DIRECTORY}/run_terraform \
		plan \
		us-east-1 \
		production

terraform-apply-production: build-docker .terraform-shared
	@export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}; \
	${TERRAFORM_SHARED_DIRECTORY}/run_terraform \
		apply \
		us-east-1 \
		production

# Release

release: build-docker github-docker-login
	@echo Tagging webservice image to ${DOCKER_REPO_IMAGE_NAME}...
	@docker tag ${DOCKER_IMAGE_NAME} ${DOCKER_REPO_IMAGE_NAME}
	@docker tag ${DOCKER_IMAGE_NAME} ${MAJOR_DOT_MINOR_VERSION_DOCKER_REPO_IMAGE_NAME}
	@docker tag ${DOCKER_IMAGE_NAME} ${LATEST_DOCKER_REPO_IMAGE_NAME}
	@echo Pushing webservice docker image to ${DOCKER_REPO_IMAGE_NAME}...
	@docker push ${DOCKER_REPO_IMAGE_NAME}
	@docker push ${MAJOR_DOT_MINOR_VERSION_DOCKER_REPO_IMAGE_NAME}
	@docker push ${LATEST_DOCKER_REPO_IMAGE_NAME}

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

lint-terraform: build-docker .terraform-shared
	@export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}; \
	${TERRAFORM_SHARED_DIRECTORY}/run_terraform \
		lint \
		us-east-1 \
		dev

# Utilities

clean:
	@echo Removing Make Target Files...
	@rm -f build-docker
	@echo Make Target Files Removed.
	@echo Removing terraform shared directory...
	@rm -rf ${TERRAFORM_SHARED_DIRECTORY}
	@echo Removed terraform shared directory.

.terraform-shared: build-docker github-docker-login
	@echo Downloading local scripts from terraform-shared to local directory '${TERRAFORM_SHARED_DIRECTORY}'...
	@docker run \
		--rm \
		-v ${TERRAFORM_SHARED_DIRECTORY}:/terraform-shared \
		--entrypoint /scripts/docker/local_install \
		${DOCKER_IMAGE_NAME} \
			local_install
	@echo Installed local scripts to ${TERRAFORM_SHARED_DIRECTORY}

github-docker-login:
	@echo ${CR_PAT} | docker login ${GITHUB_REPO} -u ${GITHUB_USER} --password-stdin