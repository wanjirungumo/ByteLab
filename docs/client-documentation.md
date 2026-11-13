# Technical Documentation: Cloud Security & DevSecOps Lab

Documentation for the end client. Each section is written by its owner and merged through a pull request.

| Section | Owner | Status |
| --- | --- | --- |
| 1. Overview and architecture | Farouq | To do |
| 2. Network and security scanning (Checkov) | Esther | To do |
| 3. Compute, Ansible and Juice Shop | Matteo | To do |
| 4. WAF (ModSecurity + OWASP CRS) | Farouq | To do |
| 5. SIEM (Wazuh) | Farouq | To do |
| 6. Deployment and operation guide | Farouq | To do |
| 7. Cost analysis | Matteo | To do |

## 1. Overview and architecture
Goal of the lab, the three VMs, traffic flow (Internet, WAF, Juice Shop, logs to Wazuh). Values in `docs/interfaces.md`.

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
