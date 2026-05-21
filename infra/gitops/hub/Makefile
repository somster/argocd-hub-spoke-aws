# Workaround: ~/.aws/credentials has uppercase key names (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY)
# which the AWS SDK does not recognise. local-aws-config.ini overrides source_profile to 'default'
# which has valid lowercase keys.
#
# Permanent fix: edit ~/.aws/credentials and rename:
#   AWS_ACCESS_KEY_ID     → aws_access_key_id
#   AWS_SECRET_ACCESS_KEY → aws_secret_access_key

TFVARS_FILE ?= terraform.tfvars
VARFILE_FLAG := $(if $(wildcard $(PWD)/$(TFVARS_FILE)),-var-file=$(PWD)/$(TFVARS_FILE),)

.PHONY: init plan apply destroy bootstrap

init:
	 terraform init

plan:
	 terraform plan $(VARFILE_FLAG)

apply:
	 terraform apply $(VARFILE_FLAG) --auto-approve

bootstrap:
	 aws eks update-kubeconfig \
		--name hub-control-plane \
		--region us-west-2 \
		--assume-role-arn arn:aws:iam::863518459040:role/system/VPB_Terraform_Access \
		--role-arn arn:aws:iam::863518459040:role/system/VPB_Terraform_Access \
		--alias hub
	 kubectl --context hub apply -f $(PWD)/bootstrap/addons.yaml

destroy:	 bash ./destroy.sh
	 terraform destroy $(VARFILE_FLAG) --auto-approve
