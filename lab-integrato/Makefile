TF := terraform -chdir=terraform

.PHONY: creds init plan up down stop start checkov out

creds: ## verifica credenziali Learner Lab (token scade a fine sessione)
	aws sts get-caller-identity

init:
	$(TF) init

plan: init
	$(TF) plan

checkov: ## scan IaC prima del deploy
	checkov --config-file terraform/.checkov.yml

up: init ## crea/aggiorna infra e file Ansible
	$(TF) apply

down: ## distrugge tutto (ferma anche i costi del NAT GW)
	$(TF) destroy

stop: ## ferma le EC2 (NAT GW e EIP continuano a costare)
	aws ec2 stop-instances --region $$($(TF) output -raw region) --instance-ids $$($(TF) output -raw instance_ids)

start:
	aws ec2 start-instances --region $$($(TF) output -raw region) --instance-ids $$($(TF) output -raw instance_ids)

out:
	$(TF) output
