DOCKER_IMAGE_NAME := tenstartups/parasite-base

build: Dockerfile.$(DOCKER_ARCH)
	docker build --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME):$(PARASITE_OS) .

clean_build: Dockerfile.$(DOCKER_ARCH)
	docker build --no-cache --pull --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME):$(PARASITE_OS) .

push: build
	docker push $(DOCKER_IMAGE_NAME):$(PARASITE_OS)

run: build
	docker run -it --rm -v $(PWD)/parasite-config:/parasite-config $(DOCKER_IMAGE_NAME):$(PARASITE_OS) $(ARGS)
