include .env
-include .local.env

TAG ?= latest

VERSION ?=

CI_COMMIT_REF_SLUG ?=
CI_COMMIT_SHORT_SHA ?=
CI_COMMIT_TAG ?=

REGISTRY_NAME ?=
REPO ?=

DOCKER_CACHE_FROM_IMAGES = $(REPO):$(TAG),$(REPO):$(CI_COMMIT_REF_SLUG),$(REPO):$(CI_COMMIT_SHORT_SHA),$(REPO):$(CI_COMMIT_TAG)
DOCKER_PORTS ?=

# WARNING: need to export the env var, otherwise docker build will fail
export DOCKER_BUILDKIT ?= 1
export COMPOSE_DOCKER_CLI_BUILD ?= 1

.DEFAULT_GOAL = help	# if you type 'make' without arguments, this is the default: show the help
.PHONY        : # Not needed here, but you can put your all your targets to be sure
                # there is no name conflict between your files and your targets.


## pull, build and tag
.PHONY: default
default: pull build tag

## login to the docker registry
.PHONY: login
login:
	echo "$(CUSTOM_REGISTRY_PASSWORD)" | docker login $(REGISTRY_NAME) --username $(CUSTOM_REGISTRY_USERNAME) --password-stdin

## pull the latest images from the registry
.PHONY: pull
pull:
	if [ -n "$(TAG)" ];  then docker pull $(REPO):$(TAG) || true; fi
	if [ -n "$(CI_COMMIT_REF_SLUG)" ] && [ -n "$(CI_COMMIT_SHORT_SHA)" ]; then docker pull $(REPO):$(CI_COMMIT_REF_SLUG)-$(CI_COMMIT_SHORT_SHA) || true; fi
	if [ -n "$(CI_COMMIT_REF_SLUG)" ];  then docker pull $(REPO):$(CI_COMMIT_REF_SLUG) || true; fi
	if [ -n "$(CI_COMMIT_SHORT_SHA)" ];  then docker pull $(REPO):$(CI_COMMIT_SHORT_SHA) || true; fi
	if [ -n "$(CI_COMMIT_TAG)" ];  then docker pull $(REPO):$(CI_COMMIT_TAG) || true; fi

## build docker image
.PHONY: build
build:
	docker build \
		--tag $(REPO):latest \
		--cache-from $(DOCKER_CACHE_FROM_IMAGES) \
		--build-arg VERSION=$(VERSION) \
		-f $(PWD)/Dockerfile \
		.

## tag the latest build
.PHONY: tag
tag:
	if [ -n "$(TAG)" ];       then docker tag $(REPO):latest $(REPO):$(TAG); fi
	if [ -n "$(CI_COMMIT_SHORT_SHA)" ]; then docker tag $(REPO):latest $(REPO):$(CI_COMMIT_SHORT_SHA); fi
	if [ -n "$(CI_COMMIT_TAG)" ];       then docker tag $(REPO):latest $(REPO):$(CI_COMMIT_TAG); fi
	if [ -n "$(CI_COMMIT_REF_SLUG)" ];  then docker tag $(REPO):latest $(REPO):$(CI_COMMIT_REF_SLUG); fi
	if [ -n "$(CI_COMMIT_REF_SLUG)" ] && [ -n "$(CI_COMMIT_SHORT_SHA)" ]; then docker tag $(REPO):latest $(REPO):$(CI_COMMIT_REF_SLUG)-$(CI_COMMIT_SHORT_SHA); fi
	if [ -n "$(VERSION)" ]; then docker tag $(REPO):latest $(REPO):$(VERSION); fi

## push the latest build to the registry
.PHONY: push
push:
	if [ -n "$(TAG)" ];       then docker push $(REPO):$(TAG); fi
	if [ -n "$(CI_COMMIT_SHORT_SHA)" ]; then docker push $(REPO):$(CI_COMMIT_SHORT_SHA); fi
	if [ -n "$(CI_COMMIT_TAG)" ];       then docker push $(REPO):$(CI_COMMIT_TAG); fi
	if [ -n "$(CI_COMMIT_REF_SLUG)" ];  then docker push $(REPO):$(CI_COMMIT_REF_SLUG); fi
	if [ -n "$(CI_COMMIT_REF_SLUG)" ] && [ -n "$(CI_COMMIT_SHORT_SHA)" ]; then docker push $(REPO):$(CI_COMMIT_REF_SLUG)-$(CI_COMMIT_SHORT_SHA); fi
	if [ -n "$(VERSION)" ]; then docker push $(REPO):$(VERSION); fi

## open a shell to the latest build
.PHONY: shell
shell:
	docker run --rm --name $(NAME) -i -t $(DOCKER_PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) sh -c "clear && (bash || sh)"

## run the latest build as it was built to do
.PHONY: run
run:
	docker run --rm --name $(NAME) $(DOCKER_PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

## run the latest build in daemon mode
.PHONY: start
start:
	docker run -d --name $(NAME) $(DOCKER_PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

## stop the running container
.PHONY: stop
stop:
	docker stop --time 1 $(NAME)

## get the latest logs
.PHONY: logs
logs:
	docker logs $(NAME)

## remove the latest builds from the local machine
.PHONY: clean
clean:
	-docker rm -f $(NAME)

## pull, build, tag and push
.PHONY: release
release: pull build tag push

## get this help page
.PHONY: help
help:
	@awk '{ \
			if ($$0 ~ /^.PHONY: [a-zA-Z\-\_\.0-9]+$$/) { \
				helpCommand = substr($$0, index($$0, ":") + 2); \
				if (helpMessage) { \
					printf "\033[36m%-40s\033[0m \t%s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^[a-zA-Z\-\_0-9.]+:/) { \
				helpCommand = substr($$0, 0, index($$0, ":")); \
				if (helpMessage) { \
					printf "\033[36m%-40s\033[0m %s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^##/) { \
				if (helpMessage) { \
					helpMessage = helpMessage"\n                                                  "substr($$0, 3); \
				} else { \
					helpMessage = substr($$0, 3); \
				} \
			} else { \
				if (helpMessage) { \
					printf "\n\033[33m%-80s\033[0m\n", \
          	helpMessage; \
				} \
				helpMessage = ""; \
			} \
		}' \
		$(MAKEFILE_LIST)