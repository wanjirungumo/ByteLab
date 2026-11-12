# Lab Cloud Security - infrastruttura AWS (Learner Lab)

Terraform crea: VPC, subnet pubblica/privata, IGW, NAT GW (opzionale), 3 EC2 Ubuntu 22.04
(WAF, Juice Shop, Wazuh), Security Group, EIP, key pair e password Wazuh generate.

```
Internet -> WAF (EIP, subnet pubblica) -> Juice Shop (privata, :3000)
                  |  jump host SSH            Wazuh (privata)
                  +-- tunnel dashboard :8443 --^
```

## Uso
```bash
# 1. credenziali dal lab (AWS Details): access key, secret, session token
export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_SESSION_TOKEN=...
make creds

# 2. variabili
cp terraform/terraform.tfvars.example terraform/terraform.tfvars   # inserire i propri IP

# 3. scan e deploy
make checkov
make up
make out                       # IP, comandi SSH, tunnel
terraform -chdir=terraform output -raw wazuh_admin_password
```
`terraform apply` genera `terraform/ansible/inventory.ini` e `terraform/ansible/group_vars/all/terraform_generated.yml`
(entrambi gitignored). Le VM private si raggiungono via ProxyCommand sul WAF.

## Fasi offens -> difens
`waf_mode` in `terraform.tfvars`: `off` (proxy senza regole, fase offens) -> `detection` -> `blocking`.
Cambiarlo e rieseguire `make up` aggiorna solo il file vars: poi rilanciare Ansible. URL invariato.

## Costi e sessioni
- `make stop` a fine sessione. NAT GW (~1 USD/giorno) ed EIP restano a pagamento: `make down` se si resta fermi giorni.
- Reset del lab cancella tutto: rebuild = `make up` + Ansible. Salvare evidenze fuori.
- Solo l'account "owner" fa apply. State locale, mai in git.

## Da verificare al primo run
- `LabInstanceProfile` esiste (altrimenti `instance_profile_name = null`).
- Ruoli IAM: il codice non ne crea.
- ID regole Checkov nei `skip-check` (alcuni ID cambiano tra versioni).
- Versione Wazuh vs Ubuntu 22.04.
- Terraform non e' stato eseguito: nessun `validate` fatto, eseguire `terraform validate`.
