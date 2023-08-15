# Build all
# VERSION ?= $(shell git rev-parse --abbrev-ref HEAD)
BUILDTIME := $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')
COMMIT := $(shell git rev-parse --short HEAD)

EXECUTABLE=komiser

GO_LD_FLAGS += -X github.com/tailwarden/komiser/internal.Version=$(VERSION)
GO_LD_FLAGS += -X github.com/tailwarden/komiser/internal.Buildtime=$(BUILDTIME)
GO_LD_FLAGS += -X github.com/tailwarden/komiser/internal.Commit=$(COMMIT)
GO_FLAGS = -ldflags "$(GO_LD_FLAGS)"

.PHONY: build package test version help

# Default target.
all: build

## build: Build for the current platform.
build:
	go build -o bin/$(EXECUTABLE) $(GO_FLAGS) .
	@echo built: bin/$(EXECUTABLE)
	@echo version: $(VERSION)
	@echo commit: $(COMMIT)

## package: Build for all supported platforms.
package:
	env GOOS=windows GOARCH=amd64 go build -o bin/$(EXECUTABLE)_windows_amd64.exe $(GO_FLAGS) .
	env GOOS=linux GOARCH=amd64 go build -o bin/$(EXECUTABLE)_linux_amd64 $(GO_FLAGS) .
	env GOOS=darwin GOARCH=amd64 go build -o bin/$(EXECUTABLE)_darwin_amd64 $(GO_FLAGS) .
	env GOOS=darwin GOARCH=arm64 go build -o bin/$(EXECUTABLE)_darwin_arm64 $(GO_FLAGS) .
	@echo built:  bin/$(EXECUTABLE)_windows_amd64.exe, bin/$(EXECUTABLE)_linux_amd64, bin/$(EXECUTABLE)_darwin_amd64, bin/$(EXECUTABLE)_darwin_arm64
	@echo version: $(VERSION)
	@echo commit: $(COMMIT)

## test: Run tests.
test:
	go test -v $(go list ./... | grep -v /dashboard/)

test-bin :

## version: Show version.
version:
	@echo version: $(VERSION)
	@echo commit: $(COMMIT)

## clean: Remove previous builds and clear test cache.
clean:
	rm -f bin/$(EXECUTABLE)*
	go clean -testcache

## help: Show this message.
help: Makefile
	@echo $(EXECUTABLE) $(VERSION)
	@echo "Available targets:"
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'

USER=dsatya6
DOCKER_IMAGE_NAME=komisercnt
ARCH=amd64
build-container :
	@echo ARCH $(ARCH)
	@docker build --platform linux/$(ARCH) -t $(USER)/$(DOCKER_IMAGE_NAME):$(ARCH) .

push-container :
	@docker push $(USER)/$(DOCKER_IMAGE_NAME):$(ARCH)

test-container :
	@docker rm -f $(DOCKER_IMAGE_NAME) || true
	@docker run --platform linux/$(ARCH) \
           -v $(HOME)/credfiles/config_docker.toml:/etc/config/config.toml  \
           -v $(HOME)/credfiles/credentials.yaml:/etc/config/credentials.yaml \
           -d -p 3000:3000 --name=$(DOCKER_IMAGE_NAME) $(USER)/$(DOCKER_IMAGE_NAME):$(ARCH) \
           komiser start --config /etc/config/config.toml
