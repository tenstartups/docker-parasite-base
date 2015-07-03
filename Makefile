DOCKER_IMAGE_NAME=tenstartups/coreos-12factor-init

build: Dockerfile
	docker build -t ${DOCKER_IMAGE_NAME} .

run: build
	docker run -it --rm ${DOCKER_IMAGE_NAME} ${ARGS}
