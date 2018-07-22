SHELL = /bin/bash
OSID ?= el7
IMAGE = ambakshi/brew-fpm:$(OSID)
NAME = brew-fpm-$(OSID)
VOLUME = brew-$(OSID)

HTTP_PROXY ?= http://192.168.1.10:3128
http_proxy ?= http://192.168.1.10:3128
DOCKER_ARGS=

all: image run shell

image:
	docker build $(DOCKER_ARGS) --build-arg=http_proxy=$(http_proxy) --build-arg=HTTP_PROXY=$(HTTP_PROXY) -t $(IMAGE) -f Dockerfile.$(OSID) .

run:
	state="$$(docker inspect $(NAME) --format '{{.State.Status}}' 2>/dev/null)"; \
		  case "$${state}" in \
		  	stopped|exited) docker start $(NAME);; \
			running) :;; \
			*) docker run -it -d --hostname `hostname -s`-$(OSID) -v $(VOLUME):/home/linuxbrew -v `pwd`:/host -e http_proxy=$(http_proxy) -e HTTP_PROXY=$(HTTP_PROXY) --name $(NAME) $(IMAGE);; \
		  esac

shell:
	@echo Entering $(NAME) ...
	@docker exec -u 1000:1000 -e HOME=/home/linuxbrew -ti $(NAME) bash -l

clean:
	-docker kill $(NAME)
	-docker rm -f $(NAME)
