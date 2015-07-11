DOCKER_IMAGE_NAME=tenstartups/coreos-12factor-init

clean_build: Dockerfile
	docker build --no-cache=true -t ${DOCKER_IMAGE_NAME} .

build: Dockerfile
	docker build -t ${DOCKER_IMAGE_NAME} .

run: build
	docker run -it --rm ${DOCKER_IMAGE_NAME} ${ARGS}
