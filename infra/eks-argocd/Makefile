# =============================================================================
# EKS + ArgoCD Terraform Makefile
# =============================================================================
# Sub-components: shared (VPC/networking), sso (IAM Identity Center), eks
# Usage:
#   make init                  - initialise all providers
#   make plan                  - plan all modules
#   make deploy                - deploy all modules
#   make destroy               - destroy all modules (safeguarded with prompt)
#
#   make deploy-shared         - deploy shared (VPC) only
#   make deploy-sso            - deploy SSO only
#   make deploy-eks            - deploy EKS only
#
#   make plan-shared           - plan shared only
#   make plan-sso              - plan SSO only
#   make plan-eks              - plan EKS only
#
#   make destroy-eks           - destroy EKS only
#   make destroy-sso           - destroy SSO only
#   make destroy-shared        - destroy shared only
#
#   make output                - show all outputs
# =============================================================================

SHELL        := /bin/bash
TF_DIR       := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TFVARS_FILE  ?= terraform.tfvars

# Terraform binary (override with TF=tofu for OpenTofu)
TF           ?= terraform

# Auto-approve flag for non-interactive runs (e.g. CI=1 make deploy)
ifeq ($(CI),1)
  AUTO_APPROVE := -auto-approve
else
  AUTO_APPROVE :=
endif

# Shared var-file flag (only applied when the file exists)
VARFILE_FLAG := $(if $(wildcard $(TF_DIR)/$(TFVARS_FILE)),-var-file=$(TFVARS_FILE),)

.DEFAULT_GOAL := help

# -----------------------------------------------------------------------------
# Phony targets
# -----------------------------------------------------------------------------
.PHONY: help init validate fmt \
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
	@echo "  validate          Validate configuration"
	@echo "  fmt               Format all .tf files"
	@echo ""
	@echo "Plan (dry-run):"
	@echo "  plan              Plan all modules"
	@echo "  plan-shared       Plan shared (VPC/networking) only"
	@echo "  plan-sso          Plan SSO (IAM Identity Center) only"
	@echo "  plan-eks          Plan EKS cluster only"
	@echo ""
	@echo "Deploy:"
	@echo "  deploy            Deploy all modules  (shared → sso → eks)"
	@echo "  deploy-shared     Deploy shared (VPC/networking) only"
	@echo "  deploy-sso        Deploy SSO (IAM Identity Center) only"
	@echo "  deploy-eks        Deploy EKS cluster only"
	@echo ""
	@echo "Destroy (reverse order):"
	@echo "  destroy           Destroy all resources  (eks → sso → shared)"
	@echo "  destroy-eks       Destroy EKS cluster only"
	@echo "  destroy-sso       Destroy SSO resources only"
	@echo "  destroy-shared    Destroy shared (VPC/networking) only"
	@echo ""
	@echo "Other:"
	@echo "  output            Show Terraform outputs"
	@echo "  clean             Remove local .terraform dirs and lock files"
	@echo ""
	@echo "Variables:"
	@echo "  TFVARS_FILE       Var-file to use (default: terraform.tfvars)"
	@echo "  TF                Terraform binary (default: terraform; use TF=tofu for OpenTofu)"
	@echo "  CI=1              Skip interactive approval prompts"
	@echo ""

# -----------------------------------------------------------------------------
# Initialise
# -----------------------------------------------------------------------------
init:
	@echo "==> Initialising root module..."
	cd $(TF_DIR) && $(TF) init -upgrade

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
# Plan — individual modules (targeted)
# -----------------------------------------------------------------------------
plan-shared: init
	@echo "==> Planning module: shared..."
	cd $(TF_DIR) && $(TF) plan $(VARFILE_FLAG) \
	  -target=module.shared

plan-sso: init
	@echo "==> Planning module: sso..."
	cd $(TF_DIR) && $(TF) plan $(VARFILE_FLAG) \
	  -target=module.sso

plan-eks: init
	@echo "==> Planning module: eks..."
	cd $(TF_DIR) && $(TF) plan $(VARFILE_FLAG) \
	  -target=module.eks

# -----------------------------------------------------------------------------
# Deploy — full stack  (shared → sso → eks to respect dependencies)
# -----------------------------------------------------------------------------
deploy: init
	@echo "==> Deploying all modules (shared → sso → eks)..."
	cd $(TF_DIR) && $(TF) apply $(VARFILE_FLAG) \
	  -target=module.shared $(AUTO_APPROVE)
	cd $(TF_DIR) && $(TF) apply $(VARFILE_FLAG) \
	  -target=module.sso $(AUTO_APPROVE)
	cd $(TF_DIR) && $(TF) apply $(VARFILE_FLAG) \
	  -target=module.eks $(AUTO_APPROVE)
	@echo "==> Full deployment complete."

# -----------------------------------------------------------------------------
# Deploy — individual modules
# -----------------------------------------------------------------------------
deploy-shared: init
	@echo "==> Deploying module: shared (VPC/networking)..."
	cd $(TF_DIR) && $(TF) apply $(VARFILE_FLAG) \
	  -target=module.shared $(AUTO_APPROVE)

deploy-sso: init
	@echo "==> Deploying module: sso (IAM Identity Center)..."
	cd $(TF_DIR) && $(TF) apply $(VARFILE_FLAG) \
	  -target=module.sso $(AUTO_APPROVE)

deploy-eks: init
	@echo "==> Deploying module: eks (EKS cluster)..."
	cd $(TF_DIR) && $(TF) apply $(VARFILE_FLAG) \
	  -target=module.eks $(AUTO_APPROVE)

# -----------------------------------------------------------------------------
# Destroy — full stack  (reverse order: eks → sso → shared)
# -----------------------------------------------------------------------------
destroy:
ifeq ($(CI),1)
	@echo "==> Destroying all modules (eks → sso → shared)..."
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.eks -auto-approve
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.sso -auto-approve
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.shared -auto-approve
	@echo "==> Full teardown complete."
else
	@echo ""
	@echo "WARNING: This will destroy ALL managed resources (eks → sso → shared)."
	@read -p "Type 'yes' to confirm: " CONFIRM && [ "$$CONFIRM" = "yes" ] || \
	  (echo "Aborted." && exit 1)
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.eks -auto-approve
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.sso -auto-approve
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.shared -auto-approve
	@echo "==> Full teardown complete."
endif

# -----------------------------------------------------------------------------
# Destroy — individual modules
# -----------------------------------------------------------------------------
destroy-eks:
ifeq ($(CI),1)
	@echo "==> Destroying module: eks..."
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.eks -auto-approve
else
	@echo ""
	@echo "WARNING: This will destroy the EKS cluster and related resources."
	@read -p "Type 'yes' to confirm: " CONFIRM && [ "$$CONFIRM" = "yes" ] || \
	  (echo "Aborted." && exit 1)
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.eks -auto-approve
endif

destroy-sso:
ifeq ($(CI),1)
	@echo "==> Destroying module: sso..."
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.sso -auto-approve
else
	@echo ""
	@echo "WARNING: This will destroy SSO (IAM Identity Center) resources."
	@read -p "Type 'yes' to confirm: " CONFIRM && [ "$$CONFIRM" = "yes" ] || \
	  (echo "Aborted." && exit 1)
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.sso -auto-approve
endif

destroy-shared:
ifeq ($(CI),1)
	@echo "==> Destroying module: shared..."
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.shared -auto-approve
else
	@echo ""
	@echo "WARNING: This will destroy shared networking (VPC, subnets, etc.)."
	@read -p "Type 'yes' to confirm: " CONFIRM && [ "$$CONFIRM" = "yes" ] || \
	  (echo "Aborted." && exit 1)
	cd $(TF_DIR) && $(TF) destroy $(VARFILE_FLAG) \
	  -target=module.shared -auto-approve
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
