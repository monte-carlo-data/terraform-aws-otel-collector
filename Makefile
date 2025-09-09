.PHONY: default sanity-check

default:
	@echo "Read the README"

sanity-check:
	# Validate TF configuration files and formatting. Used in CI pipeline.
	terraform init -backend=false
	terraform fmt -recursive -check -diff
	terraform validate
