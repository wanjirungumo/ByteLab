# Technical Documentation: Cloud Security & DevSecOps Lab

Documentation for the end client. Each section is written by its owner and merged through a pull request.

| Section | Owner | Status |
| --- | --- | --- |
| 1. Overview and architecture | Farouq | To do |
| 2. Network and security scanning (Checkov) | Esther | To do |
| 3. Compute, Ansible and Juice Shop | Matteo | To do |
| 4. WAF (ModSecurity + OWASP CRS) | Farouq | Draft |
| 5. SIEM (Wazuh) | Farouq | Draft |
| 6. Deployment and operation guide | Farouq | Draft |
| 7. Cost analysis | Matteo | To do |

## 1. Overview and architecture
Goal of the lab, the three VMs, traffic flow (Internet, WAF, Juice Shop, logs to Wazuh). Values in `docs/interfaces.md`.

## 2. Network and security scanning
VPC, subnets, gateways, security groups. Checkov findings, fixes and accepted risks (`docs/checkov-report.md`).

## 3. Compute, Ansible and Juice Shop
Instances, inventory, base playbook, Juice Shop role.

## 4. WAF (ModSecurity + OWASP CRS)

`vm-waf` (10.10.1.10, Elastic IP) is the only public entry point. It runs Apache with ModSecurity and the OWASP Core Rule Set as a reverse proxy in front of Juice Shop on `vm-juiceshop` (port 3000). It is also the SSH jump host for the private instances.

Role: `ansible/roles/modsecurity`, playbook `ansible/site-waf.yml`.

| Variable | Default | Meaning |
| --- | --- | --- |
| `modsec_backend_url` | `http://10.10.2.10:3000/` | Backend the WAF proxies to (built from `juice_shop_ip` and `juice_shop_port`) |
| `waf_mode` | `blocking` | `off` = Off, `detection` = DetectionOnly, `blocking` = On |

`waf_mode` allows the offence-to-defence phases of the lab: start with `off`, then `detection` (attacks are logged but pass), then `blocking` (attacks get a 403).

Checking blocked requests: every event is written to `/var/log/apache2/modsec_audit.log`. Each entry lists the matched rule IDs (for example 941xxx for XSS, 942xxx for SQL injection).

Test results (13/11/2026, standalone EC2 test instance with Juice Shop on the same host, `modsec_backend_url=http://127.0.0.1:3000`):

| Test | Result |
| --- | --- |
| `GET /` | 200, Juice Shop served through the WAF |
| `GET /?q=<script>alert(1)</script>` | 403, rules 941100, 941110, 941160 |
| `POST /rest/user/login` with SQL injection | 403, rule 942100 (libinjection) |
| `SecRuleEngine` | On (`Engine-Mode: ENABLED`) |

The playbook is idempotent: a second run only changed the virtual host. Full report: `docs/test-T13-modsecurity.md`.

Still to verify on the Terraform environment: backend `10.10.2.10:3000` reachable from `vm-waf`, access through the Elastic IP, and forwarding of WAF logs to Wazuh.

## 5. SIEM (Wazuh)

`vm-wazuh` (10.10.2.20, private subnet, at least 8 GB RAM) runs the Wazuh server in all-in-one mode: indexer, manager and dashboard.

Roles: `ansible/roles/wazuh_server` (playbook `ansible/site-wazuh.yml`) and `ansible/roles/wazuh_agent` (playbook `ansible/site-agents.yml`, installed on `vm-waf` and `vm-juiceshop`).

| Variable | Default | Meaning |
| --- | --- | --- |
| `wazuh_version` | `4.9` | Wazuh version installed |
| `wazuh_install_dir` | `/opt/wazuh-install` | Installer working directory and generated credentials |
| `wazuh_admin_user` | `admin` | Dashboard user |
| `wazuh_manager_ip` | `10.10.2.20` | Manager address used by the agents (overridden by Terraform's generated variables) |

Ports: agents connect to the manager on 1514 (events) and 1515 (enrolment). The dashboard listens on 443 and is reached through an SSH tunnel via `vm-waf`; the exact tunnel command is printed by `make out`.

Admin password: set by Terraform (`wazuh_admin_password`). If it is not defined, the installer generates one, stored in `/opt/wazuh-install/wazuh-install-files.tar`.

Test results (13/11/2026, standalone EC2 test instance, t3.large, 50 GB):

| Test | Result |
| --- | --- |
| Playbook | `ok=6 changed=4 failed=0 skipped=1` |
| Installation | Completed in under 40 minutes |
| Services | `wazuh-indexer`, `wazuh-manager`, `wazuh-dashboard` active |
| Dashboard | HTTPS login as admin succeeded (self-signed certificate) |

Full report: `docs/test-T12-wazuh.md`.

Still to verify on the Terraform environment: dashboard through the jump host, ports 1514 and 1515 from the two agents, agent enrolment, WAF logs visible in Wazuh, admin password set by Terraform.

## 6. Deployment and operation guide

Terraform builds the AWS infrastructure (VPC, subnets, gateways, security groups, 3 EC2 instances, Elastic IP, key pair, generated Wazuh password). Ansible configures the instances. Details and notes: `docs/deploy-notes.md`.

1. Export the Learner Lab credentials (access key, secret key, session token) and run `make creds`.
2. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and enter the team IP addresses.
3. Run `make checkov` to scan the Terraform code, then `make up` to deploy.
4. Run `make out` to get the IP addresses, the SSH commands and the dashboard tunnel command. The Wazuh admin password is available with `terraform -chdir=terraform output -raw wazuh_admin_password`.
5. `terraform apply` generates the Ansible inventory and variables (`terraform/ansible/`, not committed). Private instances are reached with a ProxyCommand through `vm-waf`.
6. Run the playbooks in this order: `ansible/site-wazuh.yml`, `ansible/site-waf.yml`, `ansible/site-agents.yml` (the agents need the server to be up first).

Changing the WAF mode: edit `waf_mode` in `terraform.tfvars` (`off`, `detection`, `blocking`), run `make up` to update the generated variables, then run `ansible/site-waf.yml` again. The public URL does not change.

Cost and session rules:

- Run `make stop` at the end of every session.
- The NAT Gateway (about 1 USD per day) and the Elastic IP are billed while they exist: run `make down` if the environment stays unused for several days.
- A Learner Lab reset deletes everything: rebuild with `make up` and the Ansible playbooks, and save evidence outside the lab.
- Only one person runs `terraform apply` at a time; the state is local and never committed.
## 7. Cost analysis
Hours, AWS costs, yearly maintenance, alternatives.
