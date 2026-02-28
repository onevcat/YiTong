SHELL := /bin/bash

.PHONY: help bootstrap update-web-assets verify verify-swift verify-web run-example clean

help:
	@echo "Available targets:"
	@echo "  make bootstrap         Install WebRenderer dependencies for maintainers"
	@echo "  make update-web-assets Rebuild and sync bundled web assets"
	@echo "  make verify            Run Swift verification and optional web verification"
	@echo "  make verify-swift      Run Swift verification only"
	@echo "  make verify-web        Run WebRenderer build verification only"
	@echo "  make run-example       Launch the minimal macOS example app"
	@echo "  make clean             Remove build artifacts"

bootstrap:
	@./scripts/bootstrap.sh

update-web-assets:
	@./scripts/update-web-assets.sh

verify:
	@./scripts/verify.sh

verify-swift:
	@if command -v xcsift >/dev/null 2>&1; then \
		swift test 2>&1 | xcsift -f toon; \
	else \
		swift test; \
	fi

verify-web:
	@cd WebRenderer && npm run build

run-example:
	@swift run YiTongExample

clean:
	@rm -rf .build
	@rm -rf WebRenderer/dist
