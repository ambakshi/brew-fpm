SHELL = /bin/bash

IMAGE = ambakshi/brew-fpm:el7
NAME = brew-fpm

http_proxy ?= http://192.168.1.10:3128

all: image

image:
	docker build --build-arg=http_proxy=$(http_proxy) -t $(IMAGE) -f Dockerfile.redhat .

run:
	-docker volume create --name brew-el7 2>/dev/null
	-docker run -it -d -v brew-el7:/home/linuxbrew -v `pwd`:/host -e http_proxy=$(http_proxy) --name brew-fpm $(IMAGE) 2>/dev/null

exec:
	docker exec -u 1000:1000 -e HOME=/home/linuxbrew -ti $(NAME) bash -l

clean:
	-docker kill $(NAME)
	-docker rm -f $(NAME)
