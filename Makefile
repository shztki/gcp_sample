.PHONY: init plan apply destroy check

init:
	@terraform init

plan: check
	@terraform plan

apply: check
	@terraform apply
	@mkdir -p ~/.ssh
	@terraform output -raw ssh_private_key > ~/.ssh/google_compute_engine
	@chmod 600 ~/.ssh/google_compute_engine
	@terraform output -raw ssh_public_key > ~/.ssh/google_compute_engine.pub
	@chmod 644 ~/.ssh/google_compute_engine.pub

destroy: check
	@terraform destroy

check:
	@terraform fmt -recursive
	@terraform fmt -check
	@terraform validate

