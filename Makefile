SSHI_VERSION = 0.9.1

.PHONY: build-container
build-container:
	docker build --pull \
	--build-arg SSHI_VERSION=$(SSHI_VERSION) \
	-t ssh-inscribe:latest .

.PHONY: genconfig
genconfig:
	@ [ ! -f .env ] && cp env-example .env || true

build: build-container genconfig
