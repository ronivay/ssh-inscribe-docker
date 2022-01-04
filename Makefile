SSHI_VERSION = 0.9.1
SSHI_UID = 1995
SSHI_GID = 1995

.PHONY: build-container
build-container:
	docker build --pull \
	--build-arg SSHI_VERSION=$(SSHI_VERSION) \
	--build-arg SSHI_UID=$(SSHI_UID) \
	--build-arg SSHI_GID=$(SSHI_GID) \
	-t ssh-inscribe:latest container/.

.PHONY: genconfig
genconfig:
	@ [ ! -f .env ] && cp env-example .env || true
	@ mkdir -p ./sshi && chown $(SSHI_UID):$(SSHI_GID) ./sshi

build: build-container genconfig
