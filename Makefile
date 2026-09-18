.DEFAULT_GOAL := help
ENV ?= dev
INV := inventories/$(ENV)/hosts.ini

# Prefer lint tools from a local .venv (created by `make tools`) if present,
# otherwise fall back to whatever is on PATH.
YAMLLINT := $(shell [ -x .venv/bin/yamllint ] && echo .venv/bin/yamllint || echo yamllint)
ANSIBLE_LINT := $(shell [ -x .venv/bin/ansible-lint ] && echo .venv/bin/ansible-lint || echo ansible-lint)

.PHONY: help tools deps lint syntax ping baseline site build clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n",$$1,$$2}'

tools: ## Create .venv with lint/build tooling (PEP 668-safe)
	python3 -m venv .venv
	.venv/bin/pip install --upgrade pip ansible-lint yamllint ansible-builder

deps: ## Install Ansible collection dependencies
	ansible-galaxy collection install -r requirements.yml

lint: ## Run yamllint + ansible-lint
	$(YAMLLINT) .
	$(ANSIBLE_LINT)

syntax: ## Syntax-check the site playbook for ENV (default dev)
	ansible-playbook -i $(INV) playbooks/site.yml --syntax-check

ping: ## Ping all hosts in ENV
	ansible all -i $(INV) -m ping

baseline: ## Apply baseline to ENV (prompts for become password)
	ansible-playbook -i $(INV) playbooks/baseline.yml --ask-become-pass

site: ## Run the full site playbook for ENV (prompts for become password)
	ansible-playbook -i $(INV) playbooks/site.yml --ask-become-pass

build: ## Build the company.infrastructure collection
	ansible-galaxy collection build collections/ansible_collections/company/infrastructure --output-path dist/ --force

clean: ## Remove build artifacts (keeps .venv)
	rm -rf dist/ terraform/generated/
