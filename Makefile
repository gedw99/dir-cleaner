BIN_ROOT_NAME=.bin
BIN_ROOT=$(PWD)/$(BIN_ROOT_NAME)

BIN_NAME=dir_cleaner

export PATH:=$(BIN_ROOT):$(PATH)

print:



mod-tidy:
	go mod tidy
mod-upgrade: mod-tidy
	go install github.com/oligot/go-mod-upgrade@latest
	go-mod-upgrade
bin:
	mkdir -p $(BIN_ROOT)
	@echo $(BIN_ROOT) >> .gitignore
	cd cmd/dir-cleaner && go build -o $(BIN_ROOT)/$(BIN_NAME)

run-h:
	$(BIN_NAME) -h

TEST_NAME=test
TEST_PATH=$(PWD)/$(TEST_NAME)
test-del:
	rm -rf $(TEST_PATH)
test-create: test-del
	mkdir -p $(TEST_PATH)
	@echo $(TEST_NAME) >> .gitignore
	cd $(TEST_PATH) && mkdir -p sub01
	cd $(TEST_PATH)/sub01 && touch Makefile README.md other.txt .gitignore
	cd $(TEST_PATH)/sub01 && mkdir -p .bin
	cd $(TEST_PATH)/sub01/.bin && touch bigfile.exe
	cd $(TEST_PATH)/sub01 && mkdir -p .dep
	cd $(TEST_PATH)/sub01/.dep && touch bigdep.exe
	cd $(TEST_PATH)/sub01 && mkdir -p .src
	cd $(TEST_PATH)/sub01/.src  && touch main.txt other.txt

test-run:
	# objective is to delete all folders and sub folders with varius .bin folders.
	cd $(TEST_PATH) && $(BIN_NAME) -h
	cd $(TEST_PATH) && $(BIN_NAME) --dry-run 
	

release-dep:
	# https://github.com/goreleaser/goreleaser
	# https://github.com/goreleaser/goreleaser/releases/tag/v2.3.2
	go install github.com/goreleaser/goreleaser/v2@v2.3.2
release: release-dep
	#goreleaser -h
	goreleaser check
	goreleaser release --snapshot --clean

TAG_VERSION=v0.1.0
TAG_MESSAGE=First release
tag:
	git tag -a $(TAG_VERSION) -m "$(TAG_MESSAGE)"
	git push origin $(TAG_VERSION)
