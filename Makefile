default: hooks

hooks:
	git config core.hooksPath .githooks

format:
	swift-format format --in-place --recursive Package.swift Sources/

lint:
	swift-format lint --recursive Package.swift Sources/

submodule:
	git submodule update --init --recursive

release:
	BUILD_TYPE=Release ./build.sh

.PHONY: format lint hooks default submodule release
