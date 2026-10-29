Last updated: 29 October 2026

## Overview

The Cloud/DevOps work is split into three parts of about 31 hours each, so every person owns one area from start to finish and nobody waits for instructions. Hours are estimates to balance the load, not a time sheet.

| Person | Part | Main deliverables | Estimated hours |
| --- | --- | --- | --- |
| Esther (team leader) | Network, security scanning, coordination | AWS network, Checkov report, board and reviews, final presentation lead | 31 |
| Matteo | Compute, Juice Shop, costs | 3 EC2 instances, Ansible inventory, Juice Shop running, Wazuh agents, cost analysis | 31 |
| Farouq | WAF, SIEM, documentation | ModSecurity WAF, Wazuh server, technical documentation | 32 |

The intermediate review (SAL), the end-to-end test and the final presentation are shared by all three and are listed at the end.

## Esther – Network, security scanning and coordination

Esther owns the AWS network everything else runs on, the Checkov security report, and the team's coordination. Her code lives in `terraform/` (root files and `network/`) and `checkov/`.

| ID | Task | Hours | Done when |
| --- | --- | --- | --- |
| T02 | Create the GitHub Projects board and load the backlog | 2 | Every task has an owner on the board |
| T03 | AWS access for the team and an AWS Budgets alert | 1 | All three can log in; alert set |
| T05 | S3 bucket for the Terraform state | 1 | `terraform init` works for all three |
| T06 | Deploy and fix the network (VPC, subnets, gateways, security groups) | 6 | `terraform apply` builds it cleanly; `destroy` removes it |
| T09 | Run Checkov on every pull request touching `terraform/` or `ansible/` | 3 | A scan result is posted on each pull request |
| T15 | First end-to-end deployment with Matteo's instances | 3 | Network and instances rebuild from scratch |
| T16 | Fix Checkov findings and write the Checkov report | 6 | Report lists findings, fixes and accepted risks |
| T19 | Hand over the environment to the cyber team | 1 | Fabio, Paolo, Samuel and Flavio can reach the app |
| — | Check-ins, pull request reviews, contact with instructors | 6 | Two or three short check-ins a week; no pull request waits more than a day |
| T24 | Lead the final presentation and backup video | 2 | Slide flow agreed; video recorded |

**Total: 31 hours.** Already done: T01 (repository) and T04 (interface agreement, see `docs/interfaces.md`).

## Matteo – Compute, Juice Shop and costs

Matteo owns the three servers, the base Ansible setup, the target app and the cost analysis. His code lives in `terraform/compute/` and `ansible/` (roles `base`, `juiceshop`, `wazuh_agent`).

| ID | Task | Hours | Done when |
| --- | --- | --- | --- |
| T07 | Terraform for the 3 EC2 instances: Ubuntu 24.04, sizes and private IPs from `docs/interfaces.md`, Elastic IP on the WAF | 6 | Instances reachable via SSH (private ones through the WAF) |
| T08 | Terraform writes `ansible/inventory.ini` from its outputs | 3 | `ansible all -m ping` succeeds |
| T10 | Base playbook: updates, basic hardening, Docker | 4 | Runs twice with no errors and no changes the second time |
| T11 | Juice Shop role | 3 | App answers on port 3000 of `vm-juiceshop` |
| T14 | Wazuh agent role on the WAF and Juice Shop instances | 4 | Both agents show as active in Wazuh |
| T17 | Lead the end-to-end test: Internet → WAF → Juice Shop, logs in Wazuh | 3 | A request shows in the WAF logs and in Wazuh |
| T21 | Instance auto-shutdown and the team hours log | 2 | Shutdown active; hours logged weekly by all three |
| T22 | Cost analysis: hours, AWS costs, yearly maintenance, alternatives | 6 | Table reviewed by Esther |

**Total: 31 hours.** Start with the Ansible hands-on exercise; it covers most of T10 and T11.

## Farouq – WAF, SIEM and documentation

Farouq owns the two security components, which are the heaviest installs, and the end-client documentation. His code lives in `ansible/` (roles `modsecurity`, `wazuh_server`) and `docs/`. He works closely with Samuel and Flavio, the defensive pair.

| ID | Task | Hours | Done when |
| --- | --- | --- | --- |
| T12 | Wazuh server role on `vm-wazuh` | 10 | Dashboard reachable for the team through the WAF jump host |
| T13 | ModSecurity + OWASP CRS role on `vm-waf`, as a reverse proxy to Juice Shop | 10 | Juice Shop opens at the WAF public IP; a basic SQL injection test is logged |
| T20 | Support Samuel and Flavio with WAF tuning and Wazuh rules | 4 | Their requests handled within a day |
| T23 | Lead the end-client technical documentation | 8 | Each section written and merged in `docs/` |

**Total: 32 hours.** Both roles can be developed on a test instance before the real environment exists, so Farouq can start right away.

## Handoffs between the three parts

These are the only points where one person waits for another. Everything else can start today.

| From | To | What is handed over | Needed for |
| --- | --- | --- | --- |
| Esther | Matteo | Network outputs: subnet IDs and security group IDs (already in the repo) | T07 instances |
| Matteo | Farouq | Running instances and the generated `inventory.ini` | Deploying T12 and T13 on the real servers |
| Farouq | Matteo | Wazuh server address and enrolment settings | T14 agents |
| Matteo + Farouq | Esther | Every pull request with Terraform or Ansible code | Checkov scan and review (T09) |
| All three | Cyber team | Working environment, IPs and access | Phases 2 and 3 (T19) |

## Shared work and rules

Three activities belong to all three, and each person presents their own part:

- **Intermediate review (SAL) rehearsal (T18):** the day before, on a freshly deployed environment.
- **Technical documentation (T23):** Farouq leads; Esther writes the network and Checkov sections, Matteo the compute, Ansible and cost sections.
- **Final presentation (T24):** Esther leads the story; Matteo presents the costs, Farouq the WAF and SIEM.

Rules for everyone:

- One branch per task named after its ID (for example `T07-compute`), merged only through a pull request reviewed by one of the other two.
- Never commit keys, `terraform.tfvars`, `backend.hcl` or state files.
- Only one person runs `terraform apply` at a time on the shared environment.
- Stop or destroy the instances at the end of every session, and log your hours every week.
- If you're blocked for more than a day, say it at the next check-in or message the team.
