default: hooks

hooks:
	git config core.hooksPath .githooks

format:
	swift-format format --in-place --recursive Package.swift Sources/

lint:
	swift-format lint --recursive Package.swift Sources/

.PHONY: format lint hooks default
