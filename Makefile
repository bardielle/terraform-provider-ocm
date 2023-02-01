#
# Copyright (c) 2021 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Disable CGO so that we always generate static binaries:
export CGO_ENABLED=0

ifeq ($(shell go env GOOS),windows)
	BINARY=terraform-provider-ocm.exe
	DESTINATION_PREFIX=$(APPDATA)/terraform.d/plugins
else
	BINARY=terraform-provider-ocm
	DESTINATION_PREFIX=$(HOME)/.terraform.d/plugins
endif

HOSTNAME=hashicorp.com
NAMESPACE=terraform-redhat
NAME=ocm
GO_ARCH=$(shell go env GOARCH)
TARGET_ARCH=$(shell go env GOOS)_${GO_ARCH}
GORELEASER_ARCH=${TARGET_ARCH}

# Import path of the project:
import_path:=github.com/terraform-redhat/terraform-provider-ocm

# Version of the project:
version:=$(shell git describe --abbrev=0 | sed 's/^v//')
commit:=$(shell git rev-parse --short HEAD)

# Set the linker flags so that the version will be included in the binaries:
ldflags:=\
	-X $(import_path)/build.Version=$(version) \
	-X $(import_path)/build.Commit=$(commit) \
	$(NULL)

.PHONY: build
build:
	go build -ldflags="$(ldflags)" -o ${BINARY}

.PHONY: install
install: build
	extension=""; \
	if [[ "${TARGET_ARCH}" =~ ^windows_.*$$ ]]; then \
	  extension=".exe"; \
	fi; \
	dir="$(DESTINATION_PREFIX)/terraform.local/local/ocm/$(version)/$(TARGET_ARCH)"; \
	file="terraform-provider-ocm_v$(version)${extension}"; \
	mkdir -p "$${dir}"; \
	mv ${BINARY} "$${dir}/$${file}"

.PHONY: subsystem-test
subsystem-test: install
	ginkgo run \
		--succinct \
		-ldflags="$(ldflags)" \
		-r \
		--focus-file subsystem/.*

.PHONY: unit-test
unit-test:
	ginkgo run \
		--succinct \
		-ldflags="$(ldflags)" \
		-r \
		--focus-file provider/.*

.PHONY: test tests
test tests: unit-test subsystem-test

.PHONY: fmt_go
fmt_go:
	gofmt -s -l -w $$(find . -name '*.go')

.PHONY: fmt_tf
fmt_tf:
	terraform fmt -recursive examples

.PHONY: fmt
fmt: fmt_go fmt_tf

.PHONY: clean
clean:
	rm -rf .terraform.d

generate:
	go generate ./...
