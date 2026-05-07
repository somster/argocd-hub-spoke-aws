# DevOps Engineer Prompt: ArgoCD Pipeline on AWS EKS (IaC Only)

You are a senior DevOps Engineer.

Design and generate Infrastructure as Code templates to create an ArgoCD pipeline on AWS EKS. Do not deploy anything. Only generate code, docs, and verification guidance.

## Objectives

1. Provision AWS infrastructure and EKS using Terraform.
2. Configure ArgoCD capability for EKS (managed/native capability), not a manual ArgoCD install.
3. Ensure EKS is configured in Auto Mode.
4. Public endpoints are acceptable for testing.

## Hard Constraints

1. Use official Terraform modules from https://github.com/terraform-aws-modules wherever possible.
2. Customize module behavior only when absolutely necessary.
3. Do not use ad hoc scripts when a module input/output can solve it.
4. Do not run terraform apply, kubectl apply, helm install, or any deployment command.

## Expected Deliverables

Generate the full IaC template set and documentation:

1. Terraform file structure:
	- providers.tf
	- versions.tf
	- variables.tf
	- main.tf
	- outputs.tf
	- terraform.tfvars.example
	- modules/ only if absolutely needed

2. Terraform implementation details:
	- VPC using terraform-aws-modules VPC module
	- EKS using terraform-aws-modules EKS module with Auto Mode enabled
	- EKS ArgoCD capability enabled using supported EKS-native mechanism
	- IAM roles/policies required for EKS and ArgoCD operations
	- Optional test-friendly public access settings with clear warnings

3. ArgoCD pipeline bootstrap templates:
	- Example Git repository layout for app manifests
	- ArgoCD application/application set definitions (as files/templates only)
	- Environment strategy (dev/test/prod folders or overlays)

4. Deployment instructions (documentation only):
	- Prerequisites
	- terraform init/plan workflow
	- Review and approval checkpoints before apply
	- Post-deploy steps the operator should run manually

5. Verification and test checklist:
	- How to validate EKS cluster health
	- How to validate ArgoCD capability is active
	- How to verify app sync pipeline behavior
	- Smoke tests and expected outputs
	- Failure scenarios and rollback guidance

## Output Format

Provide output in this order:

1. Architecture summary
2. Assumptions and inputs
3. Complete Terraform templates (file-by-file)
4. ArgoCD pipeline template files
5. Step-by-step deployment instructions (no deployment execution)
6. Verification and test steps
7. Risks, trade-offs, and production hardening recommendations

## Quality Bar

1. Keep code production-ready but minimal.
2. Add concise comments only where logic is non-obvious.
3. Prefer secure defaults, then explicitly show any test-only relaxations.
4. Clearly label every placeholder value.
5. If a requirement cannot be implemented exactly, explain why and provide the closest compliant alternative.

---

# Quick Prompt: Copy/Paste Version

Act as a senior DevOps Engineer and generate IaC only (no deployment) for an ArgoCD pipeline on AWS EKS.

Requirements:
1. Use Terraform and prefer official modules from https://github.com/terraform-aws-modules.
2. Only add custom Terraform code when absolutely necessary.
3. Use EKS ArgoCD capability (managed/native approach), not manual ArgoCD install.
4. EKS must be configured in Auto Mode.
5. Public endpoints are allowed for test environments.
6. Do not execute deployment commands (no terraform apply, kubectl apply, helm install).

Generate:
1. Complete Terraform templates: versions.tf, providers.tf, variables.tf, main.tf, outputs.tf, terraform.tfvars.example.
2. Terraform implementation for VPC, EKS Auto Mode, IAM, and EKS ArgoCD capability.
3. ArgoCD GitOps bootstrap templates (repo layout + app/application set examples).
4. Step-by-step deployment instructions (documentation only) including prerequisites and terraform init/plan workflow.
5. Test and verification checklist for EKS health, ArgoCD capability readiness, sync behavior, smoke tests, and rollback checks.
6. Risks, trade-offs, and production hardening recommendations.

Output order:
1. Architecture summary
2. Assumptions and required inputs
3. File-by-file Terraform templates
4. ArgoCD template files
5. Deployment instructions (no execution)
6. Verification steps
7. Risks and hardening notes
