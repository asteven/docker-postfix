#REGISTRY = docker.io
#IMG_NAMESPACE = asteven
REGISTRY = registry.core.hpc.ethz.ch
IMG_NAMESPACE = ethz-hpc
IMG_NAME = postfix
IMG_FQNAME = $(REGISTRY)/$(IMG_NAMESPACE)/$(IMG_NAME)
IMG_VERSION = 0.2.6
# Prefere podman over docker for building.
BUILDER = $(shell which podman || which docker)

.PHONY: container push clean
all: container

container:
	# Build the runtime stage
	sudo $(BUILDER) build --pull \
		--tag $(IMG_FQNAME):$(IMG_VERSION) \
		--tag $(IMG_FQNAME):latest .

push:
	sudo $(BUILDER) push $(IMG_FQNAME):$(IMG_VERSION) docker://$(IMG_FQNAME):$(IMG_VERSION)
	# Also update :latest
	sudo $(BUILDER) push $(IMG_FQNAME):latest docker://$(IMG_FQNAME):latest

clean:
	sudo $(BUILDER) rmi $(IMG_FQNAME):$(IMG_VERSION)
	sudo $(BUILDER) rmi $(IMG_FQNAME):latest

