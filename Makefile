PARASITE_OS ?= $(shell bash -c 'read -s -p "Parasite OS : " os; echo $$os')
DOCKER_IMAGE_NAME := tenstartups/$(PARASITE_OS)-parasite-base
ifeq ($(DOCKER_ARCH),rpi)
	DOCKER_IMAGE_NAME := $(subst /,/$(DOCKER_ARCH)-,$(DOCKER_IMAGE_NAME))
endif

build: Dockerfile.$(DOCKER_ARCH)
	docker build --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

clean_build: Dockerfile.$(DOCKER_ARCH)
	docker build --no-cache --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

push: build
	docker push ${DOCKER_IMAGE_NAME}

run: build
	docker run -it --rm --env-file=environment --net=host ${DOCKER_IMAGE_NAME} ${ARGS}
