# create_IAC

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
