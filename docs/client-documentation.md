# Technical Documentation: Cloud Security & DevSecOps Lab

Documentation for the end client. Each section is written by its owner and merged through a pull request.

| Section | Owner | Status |
| --- | --- | --- |
| 1. Overview and architecture | Farouq | Draft |
| 2. Network and security scanning (Checkov) | Esther | To do |
| 3. Compute, Ansible and Juice Shop | Matteo | To do |
| 4. WAF (ModSecurity + OWASP CRS) | Farouq | To do |
| 5. SIEM (Wazuh) | Farouq | To do |
| 6. Deployment and operation guide | Farouq | To do |
| 7. Cost analysis | Matteo | To do |

## 1. Overview and architecture

The lab gives the cyber team a realistic target and a realistic defence on AWS. OWASP Juice Shop, a deliberately vulnerable web application, is published only behind a Web Application Firewall (ModSecurity with the OWASP Core Rule Set) and monitored by a SIEM (Wazuh).

The lab runs in three phases, controlled by the `waf_mode` variable:

| Phase | `waf_mode` | Behaviour |
| --- | --- | --- |
| Attack | `off` | The WAF forwards everything; attacks reach Juice Shop |
| Detection | `detection` | Attacks are logged but not stopped |
| Defence | `blocking` | Attacks matching a rule are blocked with a 403 |

### Architecture

| Instance | Subnet | Private IP | Public IP | Role |
| --- | --- | --- | --- | --- |
| `vm-waf` | Public (10.10.1.0/24) | 10.10.1.10 | Elastic IP | WAF reverse proxy and SSH jump host |
| `vm-juiceshop` | Private (10.10.2.0/24) | 10.10.2.10 | None | Juice Shop in Docker, port 3000 |
| `vm-wazuh` | Private (10.10.2.0/24) | 10.10.2.20 | None | Wazuh server (indexer, manager, dashboard) |

The VPC uses `10.10.0.0/16` in `us-east-1`. Private instances reach the Internet through a NAT Gateway. Resource names start with `lab-cloudsec-`.

    Internet --> vm-waf (ports 80/443) --> vm-juiceshop (port 3000)
                    |                            |
                    +---- Wazuh agents ----------+--> vm-wazuh (ports 1514/1515)

    Team --> SSH to vm-waf (jump host) --> private instances
    Team --> SSH tunnel through vm-waf --> Wazuh dashboard (port 443)

### How it works

1. Users and attackers reach the application only through the WAF. Juice Shop and Wazuh have no public IP.
2. The WAF inspects each request against the OWASP rules, then forwards clean requests to Juice Shop.
3. Agents on `vm-waf` and `vm-juiceshop` send logs and events to the Wazuh server, so blocked attacks can be investigated in the dashboard.
4. The team administers everything through `vm-waf`. The detailed network rules (security groups) are in section 2.

### Tools

| Tool | Use |
| --- | --- |
| Terraform | Builds the AWS infrastructure and generates the Ansible inventory |
| Ansible | Installs and configures the WAF, Juice Shop, Wazuh server and agents |
| Checkov | Scans Terraform and Ansible code on every pull request |

The agreed network and instance values are kept in `docs/interfaces.md`.
## 2. Network and security scanning
VPC, subnets, gateways, security groups. Checkov findings, fixes and accepted risks (`docs/checkov-report.md`).

## 3. Compute, Ansible and Juice Shop
Instances, inventory, base playbook, Juice Shop role.

## 4. WAF (ModSecurity + OWASP CRS)
Role `modsecurity`, variables (`modsec_backend_url`, `waf_mode`), how to check blocked requests in `modsec_audit.log`. Test results: `docs/test-T13-modsecurity.md`.

## 5. SIEM (Wazuh)
Role `wazuh_server`, agents, ports 1514 and 1515, dashboard access through the jump host. Test results: `docs/test-T12-wazuh.md`.

## 6. Deployment and operation guide
Steps to deploy, destroy and redeploy the environment. See `docs/deploy-notes.md`.

## 7. Cost analysis
Hours, AWS costs, yearly maintenance, alternatives.
