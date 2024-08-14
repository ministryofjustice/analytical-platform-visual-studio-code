.PHONY: test build run

IMAGE_NAME ?= ghcr.io/ministryofjustice/analytical-platform-visual-studio-code
IMAGE_TAG  ?= local

run: build
	docker run --rm -it --publish 8080:8080 $(IMAGE_NAME):$(IMAGE_TAG)

test: build
	container-structure-test test --platform linux/amd64 --config test/container-structure-test.yml --image $(IMAGE_NAME):$(IMAGE_TAG)

build:
	@ARCH=`uname --machine`; \
	case $$ARCH in \
	aarch64 | arm64) \
		echo "Building on $$ARCH architecture"; \
		docker build --platform linux/amd64 --file Dockerfile --tag $(IMAGE_NAME):$(IMAGE_TAG) . ;; \
	*) \
		echo "Building on $$ARCH architecture"; \
		docker build --file Dockerfile --tag $(IMAGE_NAME):$(IMAGE_TAG) . ;; \
	esac
