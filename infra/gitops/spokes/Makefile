# Workaround: ~/.aws/credentials has uppercase key names (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY)
# which the AWS SDK does not recognise. local-aws-config.ini overrides source_profile to 'default'
# which has valid lowercase keys.
#
# Permanent fix: edit ~/.aws/credentials and rename:
#   AWS_ACCESS_KEY_ID     -> aws_access_key_id
#   AWS_SECRET_ACCESS_KEY -> aws_secret_access_key

ENV ?=
TFVARS_FILE := workspaces/$(ENV).tfvars

.PHONY: init workspace-check plan apply destroy bootstrap

workspace-check:
ifndef ENV
	$(error ENV is not set. Usage: make <target> ENV=dev)
endif
	@test -f "$(TFVARS_FILE)" || (echo "Missing tfvars file: $(TFVARS_FILE)" && exit 1)

init: workspace-check
	@echo "Initializing backend for workspace $(ENV)"
	@terraform init -backend-config="key=gitops/spoke-$(ENV).tfstate"
	@if terraform workspace list | grep -q "$(ENV)"; then \
		terraform workspace select "$(ENV)"; \
	else \
		terraform workspace new "$(ENV)"; \
	fi

plan: workspace-check
	@if terraform workspace list | grep -q "$(ENV)"; then \
		echo "Workspace $(ENV) already exists."; \
	else \
		terraform workspace new "$(ENV)"; \
	fi
	terraform workspace select "$(ENV)"
	terraform plan -var-file="$(TFVARS_FILE)"

apply: workspace-check
	bash ./deploy.sh "$(ENV)"

destroy: workspace-check
	bash ./destroy.sh "$(ENV)"

bootstrap:
	 aws eks update-kubeconfig \
		--name spoke-"${ENV}" \
		--region us-west-2 \
		--assume-role-arn arn:aws:iam::863518459040:role/system/VPB_Terraform_Access \
		--role-arn arn:aws:iam::863518459040:role/system/VPB_Terraform_Access \
		--alias dev