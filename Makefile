DOCKER_IMAGE_NAME := tenstartups/$(PARASITE_OS)-parasite-base

build: Dockerfile.$(DOCKER_ARCH)
	docker build --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

clean_build: Dockerfile.$(DOCKER_ARCH)
	docker build --no-cache --pull --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

push: build
	docker push ${DOCKER_IMAGE_NAME}

run: build
	docker run -it --rm --env-file=environment --net=host ${DOCKER_IMAGE_NAME} ${ARGS}
