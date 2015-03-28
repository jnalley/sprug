.PHONY: setup build

all: setup build

buildroot/.config:
	@./sprug.sh setup

setup: buildroot/.config

build: setup
	@./sprug.sh build
