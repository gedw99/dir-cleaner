# original upstream: https://github.com/guumaster/dir-cleaner

# shells for github: https://dev.to/pwd9000/github-actions-all-the-shells-581h

# os

BASE_SHELL_OS_NAME := $(shell uname -s | tr A-Z a-z)
BASE_SHELL_OS_ARCH := $(shell uname -m | tr A-Z a-z)

GO_BIN_NAME=go
ifeq ($(BASE_SHELL_OS_NAME),windows)
	GO_BIN_NAME=go.exe
endif


# go

BASE_GO_OS_NAME := $(shell $(GO_BIN_NAME) env GOOS)
BASE_CO_OS_ARCH := $(shell $(GO_BIN_NAME) env GOARCH)


# bin

BIN_ROOT_NAME=.bin
BIN_ROOT=$(PWD)/$(BIN_ROOT_NAME)

MOD_UPGRADE_BIN_NAME=go-mod-upgrade
ifeq ($(BASE_GO_OS_NAME),windows)
	MOD_UPGRADE_BIN_NAME=go-mod-upgrade.exe
endif

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
	@echo "GO_BIN_NAME:            $(GO_BIN_NAME)"
	@echo "MOD_UPGRADE_BIN_NAME:   $(MOD_UPGRADE_BIN_NAME)"
	@echo "TREE_BIN_NAME:          $(TREE_BIN_NAME)"
	@echo "BIN_NAME:               $(BIN_NAME)"
	@echo ""


## This is called by CI, so that we build for each OS and do the tests we want.
ci-test: print bin test

### mod

# go build -modfile path/to/projectb/go.mod

MOD_ORIGINAL=github.com/guumaster/dir-cleaner

# TODO. weite a ifelse, to check if we are on the MOD_ORIGINAL
# Then pick the right MOD_FILE
#MOD_FILE=go.mod
# HARDCODED FOR now to my fork.
MOD_FILE=local.go.mod

mod-print:
	@echo ""
	@echo "- mod"
	@echo "MOD_ORIGINAL:     $(MOD_ORIGINAL)"
	@echo "MOD_FILE:       $(MOD_FILE)"
	@echo ""

mod-fork:
	# ONLY run this is yout  on a fork !!

	# TODO: ONCE WE have MOD_ORIGINAL checking, we can call mod-fork, checking as part of the make call chain.
	# then setup for TaskFile, after i get Make working for everyone.

	# create replace directive.
	# see: https://www.jvt.me/posts/2022/07/07/go-mod-fork/

	# https://github.com/gedw99/dir-cleaner

	
	$(GO_BIN_NAME) mod edit -modfile $(MOD_FILE) -replace github.com/guumaster/dir-cleaner=github.com/gedw99/dir-cleaner@master
	$(MAKE) mod-tidy
mod-tidy:
	$(GO_BIN_NAME) mod tidy -modfile $(MOD_FILE)
mod-upgrade: mod-tidy
	# https://github.com/oligot/go-mod-upgrade
	$(GO_BIN_NAME) install github.com/oligot/go-mod-upgrade@latest
	# ensure it uses the right Modfile. BUT THRRE IS NOT -modfile flag ?
	$(MOD_UPGRADE_BIN_NAME) -h

### bin and run

bin-del:
	rm -rf $(BIN_ROOT)
bin: bin-del
	mkdir -p $(BIN_ROOT)
	@echo $(BIN_ROOT_NAME) >> .gitignore
	cd cmd/dir-cleaner && $(GO_BIN_NAME) build -o $(BIN_ROOT)/$(BIN_NAME)
bin-cross:
	# let goreleaaer do it

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

	# need this to see whats going on inside CI.
	# This works correctly on Windows ARM64 ( and darwin and linux ), so its correct to use it for testing.
	# https://github.com/a8m/tree
	$(GO_BIN_NAME) install github.com/a8m/tree/cmd/tree@latest

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
	$(GO_BIN_NAME) test ./...
	#cd tests && $(GO_BIN_NAME) test ./...

### tag and release 

TAG_VERSION=v0.1.0
TAG_MESSAGE=First release
tag:
	git tag -a $(TAG_VERSION) -m "$(TAG_MESSAGE)"
	git push origin $(TAG_VERSION)

release-dep:
	# https://github.com/goreleaser/goreleaser
	# https://github.com/goreleaser/goreleaser/releases/tag/v2.3.2
	$(GO_BIN_NAME) install github.com/goreleaser/goreleaser/v2@v2.3.2
release: release-dep
	goreleaser check
	goreleaser release --snapshot --clean

