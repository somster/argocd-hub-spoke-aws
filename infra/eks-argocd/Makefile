# =============================================================================
# EKS + ArgoCD Terraform Makefile
# =============================================================================
# Stack modules: shared (VPC/networking), sso (IAM Identity Center), eks
# This repository is managed as a single Terraform root module. Routine
# operations should run at the root without using -target.
# Usage:
#   make init                  - initialise all providers
#   make plan                  - plan all modules
#   make deploy                - deploy all modules
#   make destroy               - destroy all modules (safeguarded with prompt)
#
#   make output                - show all outputs
# =============================================================================

SHELL        := /bin/bash
TF_DIR       := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TFVARS_FILE  ?= terraform.tfvars

# Terraform binary (override with TF=tofu for OpenTofu)
TF           ?= terraform

# Optional flags for terraform init (for example: INIT_FLAGS=-upgrade)
INIT_FLAGS   ?=

# Always auto-approve Terraform apply operations.
AUTO_APPROVE := -auto-approve

# Shared var-file flag (only applied when the file exists)
VARFILE_FLAG := $(if $(wildcard $(TF_DIR)/$(TFVARS_FILE)),-var-file=$(TFVARS_FILE),)

.DEFAULT_GOAL := help

# -----------------------------------------------------------------------------
# Phony targets
# -----------------------------------------------------------------------------
.PHONY: help init init-upgrade validate fmt \
        plan plan-shared plan-sso plan-eks \
        deploy deploy-shared deploy-sso deploy-eks \
        destroy destroy-shared destroy-sso destroy-eks \
        output clean

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------
help:
	@echo ""
	@echo "Usage: make <target> [TFVARS_FILE=<file>] [CI=1]"
	@echo ""
	@echo "Lifecycle:"
	@echo "  init              Initialise Terraform providers and modules"
	@echo "  init-upgrade      Initialise providers and upgrade locked modules/providers"
	@echo "  validate          Validate configuration"
	@echo "  fmt               Format all .tf files"
	@echo ""
	@echo "Plan (dry-run):"
	@echo "  plan              Plan all modules"
	@echo "  plan-shared       Unsupported for this root module; use 'make plan'"
	@echo "  plan-sso          Unsupported for this root module; use 'make plan'"
	@echo "  plan-eks          Unsupported for this root module; use 'make plan'"
	@echo ""
	@echo "Deploy:"
	@echo "  deploy            Deploy the full stack"
	@echo "  deploy-shared     Unsupported for this root module; use 'make deploy'"
	@echo "  deploy-sso        Unsupported for this root module; use 'make deploy'"
	@echo "  deploy-eks        Unsupported for this root module; use 'make deploy'"
	@echo ""
	@echo "Destroy:"
	@echo "  destroy           Destroy the full stack"
	@echo "  destroy-eks       Unsupported for this root module; use 'make destroy'"
	@echo "  destroy-sso       Unsupported for this root module; use 'make destroy'"
	@echo "  destroy-shared    Unsupported for this root module; use 'make destroy'"
	@echo ""
	@echo "Other:"
	@echo "  output            Show Terraform outputs"
	@echo "  clean             Remove local .terraform dirs and lock files"
	@echo ""
	@echo "Variables:"
	@echo "  TFVARS_FILE       Var-file to use (default: terraform.tfvars)"
	@echo "  TF                Terraform binary (default: terraform; use TF=tofu for OpenTofu)"
	@echo "  INIT_FLAGS        Extra flags for 'terraform init' (example: INIT_FLAGS=-upgrade)"
	@echo "  CI=1              Skip interactive approval prompts"
	@echo ""

# -----------------------------------------------------------------------------
# Initialise
# -----------------------------------------------------------------------------
init:
	@echo "==> Initialising root module..."
	cd $(TF_DIR) && $(TF) init $(INIT_FLAGS)

init-upgrade: INIT_FLAGS := -upgrade
init-upgrade: init

# -----------------------------------------------------------------------------
# Validate / Format
# -----------------------------------------------------------------------------
validate: init
	@echo "==> Validating configuration..."
	cd $(TF_DIR) && $(TF) validate

fmt:
	@echo "==> Formatting .tf files..."
	cd $(TF_DIR) && $(TF) fmt -recursive

# -----------------------------------------------------------------------------
# Plan — full stack
# -----------------------------------------------------------------------------
plan: init
	@echo "==> Planning all modules..."
	cd $(TF_DIR) && $(TF) plan $(VARFILE_FLAG)

# -----------------------------------------------------------------------------
# Plan — individual modules
# -----------------------------------------------------------------------------
plan-shared:
	@echo "ERROR: module-specific plans are not supported for this Terraform root module. Use 'make plan'."
	@exit 1

plan-sso:
	@echo "ERROR: module-specific plans are not supported for this Terraform root module. Use 'make plan'."
	@exit 1

plan-eks:
	@echo "ERROR: module-specific plans are not supported for this Terraform root module. Use 'make plan'."
	@exit 1

# -----------------------------------------------------------------------------
# Deploy — full stack
# -----------------------------------------------------------------------------
deploy: init
	@echo "==> Deploying full stack..."
	cd $(TF_DIR) && $(TF) apply $(VARFILE_FLAG) $(AUTO_APPROVE)
	@echo "==> Deployment complete."

# -----------------------------------------------------------------------------
# Deploy — individual modules
# -----------------------------------------------------------------------------
deploy-shared: init
	@echo "ERROR: module-specific deploys are not supported for this Terraform root module. Use 'make deploy'."
	@exit 1

deploy-sso: init
	@echo "ERROR: module-specific deploys are not supported for this Terraform root module. Use 'make deploy'."
	@exit 1

deploy-eks: init
	@echo "ERROR: module-specific deploys are not supported for this Terraform root module. Use 'make deploy'."
	@exit 1

# -----------------------------------------------------------------------------
# Destroy — full stack
# -----------------------------------------------------------------------------
destroy:
ifeq ($(CI),1)
	@echo "==> Destroying full stack..."
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) -auto-approve
	@echo "==> Teardown complete."
else
	@echo ""
	@echo "WARNING: This will destroy ALL managed resources in this stack."
	@read -p "Type 'yes' to confirm: " CONFIRM && [ "$$CONFIRM" = "yes" ] || \
	  (echo "Aborted." && exit 1)
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) -auto-approve
	@echo "==> Teardown complete."
endif

# -----------------------------------------------------------------------------
# Destroy — individual modules
# -----------------------------------------------------------------------------
destroy-eks:
ifeq ($(CI),1)
	@echo "ERROR: module-specific destroys are not supported for this Terraform root module. Use 'make destroy'."
	@exit 1
else
	@echo ""
	@echo "ERROR: module-specific destroys are not supported for this Terraform root module. Use 'make destroy'."
	@exit 1
endif

destroy-sso:
ifeq ($(CI),1)
	@echo "ERROR: module-specific destroys are not supported for this Terraform root module. Use 'make destroy'."
	@exit 1
else
	@echo ""
	@echo "ERROR: module-specific destroys are not supported for this Terraform root module. Use 'make destroy'."
	@exit 1
endif

destroy-shared:
ifeq ($(CI),1)
	@echo "ERROR: module-specific destroys are not supported for this Terraform root module. Use 'make destroy'."
	@exit 1
else
	@echo ""
	@echo "ERROR: module-specific destroys are not supported for this Terraform root module. Use 'make destroy'."
	@exit 1
endif

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output:
	@echo "==> Terraform outputs:"
	cd $(TF_DIR) && $(TF) output

# -----------------------------------------------------------------------------
# Clean local state artefacts
# -----------------------------------------------------------------------------
clean:
	@echo "==> Removing local Terraform artefacts..."
	find $(TF_DIR) -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find $(TF_DIR) -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "==> Clean complete (remote state and tfvars untouched)."
