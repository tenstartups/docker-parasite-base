DOCKER_IMAGE_NAME=tenstartups/$(PARASITE_OS)-parasite-base
DOCKER_ARCH := $(shell uname -m)
ifneq (,$(findstring arm,$(DOCKER_ARCH)))
	DOCKER_PLATFORM := rpi
else
	DOCKER_PLATFORM := x64
endif

build: Dockerfile.${DOCKER_PLATFORM}
	docker build --file Dockerfile.${DOCKER_PLATFORM} --tag ${DOCKER_IMAGE_NAME} .

clean_build: Dockerfile.${DOCKER_PLATFORM}
	docker build --no-cache --file Dockerfile.${DOCKER_PLATFORM} --tag ${DOCKER_IMAGE_NAME} .

push: build
	docker push ${DOCKER_IMAGE_NAME}

run: build
	docker run -it --rm --env-file=environment --net=host ${DOCKER_IMAGE_NAME} ${ARGS}
