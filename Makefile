DOCKER_IMAGE_NAME=tenstartups/coreos-12factor-base

clean_build: Dockerfile
	docker build --no-cache=true -t ${DOCKER_IMAGE_NAME} .

build: Dockerfile
	docker build -t ${DOCKER_IMAGE_NAME} .

run: build
	docker run -it --rm --env-file=environment -e STAGE=stage -e ROLE=role --net host ${DOCKER_IMAGE_NAME} ${ARGS}
