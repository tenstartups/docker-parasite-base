DOCKER_IMAGE_NAME := tenstartups/parasite-base:$(PARASITE_OS)

build: Dockerfile.$(DOCKER_ARCH)
	docker build --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

clean_build: Dockerfile.$(DOCKER_ARCH)
	docker build --no-cache --pull --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

push: build
	docker push $(DOCKER_IMAGE_NAME)

run: build
	docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(PWD)/parasite-config:/parasite-config -e PARASITE_VAR=test $(DOCKER_IMAGE_NAME) $(ARGS)
