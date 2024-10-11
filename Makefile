# original upstream: https://github.com/guumaster/dir-cleaner


BIN_ROOT_NAME=.bin
BIN_ROOT=$(PWD)/$(BIN_ROOT_NAME)

BIN_NAME=dir_cleaner

export PATH:=$(BIN_ROOT):$(PATH)

print:

## This is called by CI, so that we build for each OS and do the tests we want.
ci-test: bin test

mod-tidy:
	go mod tidy
mod-upgrade: mod-tidy
	go install github.com/oligot/go-mod-upgrade@latest
	go-mod-upgrade
bin:
	mkdir -p $(BIN_ROOT)
	@echo $(BIN_ROOT_NAME) >> .gitignore
	cd cmd/dir-cleaner && go build -o $(BIN_ROOT)/$(BIN_NAME)

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

	## double nest it 
	mkdir -p $(TEST_ROOT)/sub01/sub
	cp -r $(TEST_ROOT)/sub01 $(TEST_ROOT)/sub01/sub/

test-run:
	# objective is to delete all folders and sub folders with varius .bin, .dep, folders.
	# works :) Toolazy to write an assertion right now..
	cd $(TEST_ROOT) && $(BIN_NAME) --verbose --pattern */.bin

	cd $(TEST_ROOT) && $(BIN_NAME) --verbose --pattern */.dep

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
