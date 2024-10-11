# original upstream: https://github.com/guumaster/dir-cleaner

# shells for github: https://dev.to/pwd9000/github-actions-all-the-shells-581h

BASE_SHELL_OS_NAME := $(shell uname -s | tr A-Z a-z)
BASE_SHELL_OS_ARCH := $(shell uname -m | tr A-Z a-z)

# os
BASE_GO_OS_NAME := $(shell go env GOOS)
BASE_CO_OS_ARCH := $(shell go env GOARCH)

BIN_ROOT_NAME=.bin
BIN_ROOT=$(PWD)/$(BIN_ROOT_NAME)

TREE_BIN_NAME=tree
ifeq ($(BASE_GO_OS_NAME),windows)
	TREE_BIN_NAME=tree.exe
endif

BIN_NAME=dir_cleaner
ifeq ($(BASE_GO_OS_NAME),windows)
	BIN_NAME=dir_cleaner.exe
endif




export PATH:=$(BIN_ROOT):$(PATH)

print:
	@echo ""
	@echo "--- base : shell ---"
	@echo "BASE_SHELL_OS_NAME:     $(BASE_SHELL_OS_NAME)"
	@echo "BASE_SHELL_OS_ARCH:     $(BASE_SHELL_OS_ARCH)"
	@echo "--- base : os ---"
	@echo "BASE_GO_OS_NAME:        $(BASE_GO_OS_NAME)"
	@echo "BASE_CO_OS_ARCH:        $(BASE_CO_OS_ARCH)"
	@echo ""
	@echo "TREE_BIN_NAME:          $(TREE_BIN_NAME)"
	@echo "BIN_NAME:               $(BIN_NAME)"
	@echo ""




## This is called by CI, so that we build for each OS and do the tests we want.
ci-test: print bin test

mod-init:
	rm -rf go.mod
	rm -rf go.sum
	go mod init github.com/gedw99/dir-cleaner
mod-tidy:
	go mod tidy
mod-upgrade: mod-tidy
	go install github.com/oligot/go-mod-upgrade@latest
	go-mod-upgrade
bin:
	mkdir -p $(BIN_ROOT)
	@echo $(BIN_ROOT_NAME) >> .gitignore
	cd cmd/dir-cleaner && go build -o $(BIN_ROOT)/$(BIN_NAME)
bin-cross:
	

run-h:
	$(BIN_NAME) -h
run-version:
	# TODO: align versioning for bin, goreleaser and dep updates.
	$(BIN_NAME) --version


TEST_ROOT_NAME=test
TEST_ROOT=$(PWD)/$(TEST_ROOT_NAME)

test: test-create test-run test-go
test-del:
	rm -rf $(TEST_ROOT)
test-create: test-del
	mkdir -p $(TEST_ROOT)
	@echo $(TEST_ROOT_NAME) >> .gitignore
	cd $(TEST_ROOT) && mkdir -p sub01
	cd $(TEST_ROOT)/sub01 && touch Makefile README.md other.txt .gitignore
	cd $(TEST_ROOT)/sub01 && mkdir -p .bin
	cd $(TEST_ROOT)/sub01/.bin && touch bigfile.exe
	cd $(TEST_ROOT)/sub01 && mkdir -p .dep
	cd $(TEST_ROOT)/sub01/.dep && touch bigdep.exe
	cd $(TEST_ROOT)/sub01 && mkdir -p .src
	cd $(TEST_ROOT)/sub01/.src  && touch main.txt other.txt

	# need this to see whats going on inside CI.
	# https://github.com/a8m/tree
	go install github.com/a8m/tree/cmd/tree@latest

	@echo ""
	@echo "- printing the test folders"
	@echo ""
	cd $(TEST_ROOT) && $(TREE_BIN_NAME) -h -a -f
	@echo ""

	## double nest it. turned off because Ubuntu hates copying folders into itself.
	#mkdir -p $(TEST_ROOT)/sub01/sub
	#cp -r $(TEST_ROOT)/sub01 $(TEST_ROOT)/sub01/sub

test-run:
	# objective is to delete all folders and sub folders with .bin, .dep, folders.
	# mac works :) Tool lazy to write an assertion right now ..

	# in ci, darwin and ubuntu work, but windows does not see these files. Might be the path symbol ?
	cd $(TEST_ROOT) && $(BIN_NAME) --verbose --pattern */.bin
	cd $(TEST_ROOT) && $(BIN_NAME) --verbose --pattern */.dep

	# Test to see if windows prefers different path symbols ?
	# Of Maybe its because i am asking CI to use a Bash shell ?
	# I tried both on Windows arm64 and neither worked
	cd $(TEST_ROOT) && $(BIN_NAME) --verbose --pattern *\.bin
	cd $(TEST_ROOT) && $(BIN_NAME) --verbose --pattern *\.dep



test-go:
	go test ./...

release-dep:
	# https://github.com/goreleaser/goreleaser
	# https://github.com/goreleaser/goreleaser/releases/tag/v2.3.2
	go install github.com/goreleaser/goreleaser/v2@v2.3.2
release: release-dep
	goreleaser check
	goreleaser release --snapshot --clean

TAG_VERSION=v0.1.0
TAG_MESSAGE=First release
tag:
	git tag -a $(TAG_VERSION) -m "$(TAG_MESSAGE)"
	git push origin $(TAG_VERSION)
