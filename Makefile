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
	cd cmd/dir-cleaner && go build -o $(BIN_ROOT)/$(BIN_NAME)

run-h:
	$(BIN_NAME) -h

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
