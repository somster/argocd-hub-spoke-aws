# Workaround: ~/.aws/credentials has uppercase key names (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY)
# which the AWS SDK does not recognise. local-aws-config.ini overrides source_profile to 'default'
# which has valid lowercase keys.
#
# Permanent fix: edit ~/.aws/credentials and rename:
#   AWS_ACCESS_KEY_ID     → aws_access_key_id
#   AWS_SECRET_ACCESS_KEY → aws_secret_access_key

TF_ENV = AWS_CONFIG_FILE=$(PWD)/local-aws-config.ini AWS_PROFILE=terraform_vpb

.PHONY: init plan apply destroy

init:
	$(TF_ENV) terraform init

plan:
	$(TF_ENV) terraform plan

apply:
	$(TF_ENV) terraform apply

destroy:
	$(TF_ENV) terraform destroy
