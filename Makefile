SHELL = /bin/bash

IMAGE = ambakshi/brew-fpm:el7

http_proxy ?= http://192.168.1.10:3128

all: image

image:
	docker build --build-arg=http_proxy=$(http_proxy) -t $(IMAGE) -f Dockerfile.redhat .

run:
	docker run -it -d -v `pwd`:/host -e http_proxy=$(http_proxy) --name brew-fpm $(IMAGE) /bin/bash -l 2>/dev/null || true
	docker exec -ti brew-fpm bash -l
