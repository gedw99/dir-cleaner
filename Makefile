# original upstream: https://github.com/guumaster/dir-cleaner

# shells for github: https://dev.to/pwd9000/github-actions-all-the-shells-581h

# os

BASE_SHELL_OS_NAME := $(shell uname -s | tr A-Z a-z)
BASE_SHELL_OS_ARCH := $(shell uname -m | tr A-Z a-z)

DEP_GO_BIN_NAME=go
ifeq ($(BASE_SHELL_OS_NAME),windows)
	DEP_GO_BIN_NAME=go.exe
endif

# go

BASE_GO_OS_NAME := $(shell $(DEP_GO_BIN_NAME) env GOOS)
BASE_CO_OS_ARCH := $(shell $(DEP_GO_BIN_NAME) env GOARCH)

# mod

# Original
MOD_PACKAGE_NAME=github.com/IGZgustavomarin/dir-cleaner
MOD_COPY_FILE=go-original.mod

# dep

DEP_ROOT_NAME=.bin
DEP_ROOT=$(PWD)/$(DEP_ROOT_NAME)

DEP_UPGRADE_BIN_NAME=go-mod-upgrade
ifeq ($(BASE_GO_OS_NAME),windows)
	DEP_UPGRADE_BIN_NAME=go-mod-upgrade.exe
endif

DEP_TREE_BIN_NAME=tree
ifeq ($(BASE_GO_OS_NAME),windows)
	DEP_TREE_BIN_NAME=tree.exe
endif


DEP_RELEASER_BIN_NAME=goreleaser
ifeq ($(BASE_GO_OS_NAME),windows)
	DEP_RELEASER_BIN_NAME=goreleaser.exe
endif

# bin

BIN_ROOT_NAME=.bin
BIN_ROOT=$(PWD)/$(BIN_ROOT_NAME)

BIN_NAME=dir_cleaner
ifeq ($(BASE_GO_OS_NAME),windows)
	BIN_NAME=dir_cleaner.exe
endif

export PATH:=$(BIN_ROOT):$(PATH)

print:
	@echo ""
	@echo "--- shell ---"
	@echo "BASE_SHELL_OS_NAME:     $(BASE_SHELL_OS_NAME)"
	@echo "BASE_SHELL_OS_ARCH:     $(BASE_SHELL_OS_ARCH)"
	@echo ""
	@echo "--- os ---"
	@echo "BASE_GO_OS_NAME:        $(BASE_GO_OS_NAME)"
	@echo "BASE_CO_OS_ARCH:        $(BASE_CO_OS_ARCH)"
	@echo ""
	@echo "--- mod ---"
	@echo "MOD_PACKAGE_NAME:       $(MOD_PACKAGE_NAME)"
	@echo "MOD_COPY_FILE:          $(MOD_COPY_FILE)"
	@echo ""
	@echo "--- dep ---"
	@echo "DEP_GO_BIN_NAME:        $(DEP_GO_BIN_NAME)"
	@echo "DEP_UPGRADE_BIN_NAME:   $(DEP_UPGRADE_BIN_NAME)"
	@echo "DEP_TREE_BIN_NAME:      $(DEP_TREE_BIN_NAME)"
	@echo "DEP_RELEASER_BIN_NAME:  $(DEP_RELEASER_BIN_NAME)"
	@echo ""
	@echo "--- go ---"
	@echo "BIN_NAME:               $(BIN_NAME)"
	@echo ""


## This is called by CI, so that we build for each OS and do the tests we want.
ci-test: print dep print bin test

### dep

dep:
	# https://github.com/oligot/go-mod-upgrade
	$(DEP_GO_BIN_NAME) install github.com/oligot/go-mod-upgrade@latest

	# need this to see whats going on inside CI.
	# This works correctly on Windows ARM64 ( and darwin and linux ), so its correct to use it for testing.
	# https://github.com/a8m/tree
	$(DEP_GO_BIN_NAME) install github.com/a8m/tree/cmd/tree@latest

	# https://github.com/goreleaser/goreleaser
	# https://github.com/goreleaser/goreleaser/releases/tag/v2.3.2
	$(DEP_GO_BIN_NAME) install github.com/goreleaser/goreleaser/v2@v2.3.2

### mod

mod-fork:
	# backup the original go.mod, so that we can use it later.
	cp go.mod $(MOD_COPY_FILE)

	# modify it to our fork namespace.
	# TODO. reflect off git to work it out ?
	$(DEP_GO_BIN_NAME) mod edit -replace $(MOD_PACKAGE_NAME)=github.com/gedw99/dir-cleaner@master
	$(MAKE) mod-tidy
mod-fork-del:
	# there is go easy way to delete the replace, so inszead we copy it back 
	cp $(MOD_COPY_FILE) go.mod
	$(MAKE) mod-tidy
mod-tidy:
	@echo go.sum >> .gitignore
	$(DEP_GO_BIN_NAME) mod tidy

mod-upgrade: mod-tidy
	$(DEP_UPGRADE_BIN_NAME)


### bin and run

bin-del:
	rm -rf $(BIN_ROOT)
bin: bin-del
	mkdir -p $(BIN_ROOT)
	@echo $(BIN_ROOT_NAME) >> .gitignore
	cd cmd/dir-cleaner && $(DEP_GO_BIN_NAME) build -o $(BIN_ROOT)/$(BIN_NAME)
bin-cross:
	# let goreleaser do it

run-h:
	$(BIN_NAME) -h
run-version:
	# TODO: align versioning for bin, goreleaser and dep updates.
	$(BIN_NAME) --version

### test

TEST_ROOT_NAME=test-golden
TEST_ROOT=$(PWD)/$(TEST_ROOT_NAME)

test: bin test-print test-create test-run test-go
test-print:
	@echo ""
	@echo "-- test golden"
	@echo "TEST_ROOT_NAME:          $(TEST_ROOT_NAME)"
	@echo "TEST_ROOT:               $(TEST_ROOT)"
	@echo ""
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

	

	@echo ""
	@echo "- printing the test folders"
	@echo ""
	cd $(TEST_ROOT) && $(DEP_TREE_BIN_NAME) -h -a -f
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
	$(DEP_GO_BIN_NAME) test ./...
	#cd tests && $(DEP_GO_BIN_NAME) test ./...

### tag and release 

TAG_VERSION=v0.1.0
TAG_MESSAGE=First release
tag:
	git tag -a $(TAG_VERSION) -m "$(TAG_MESSAGE)"
	git push origin $(TAG_VERSION)
	
release: 
	$(DEP_RELEASER_BIN_NAME) check
	$(DEP_RELEASER_BIN_NAME) release --snapshot --clean

