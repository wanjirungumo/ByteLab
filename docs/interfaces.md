# Interface agreement — ByteLab (Group 1)

Agreed values that everyone codes against. Do not change them without telling the team.

## Network

| Item | Value | Notes |
| --- | --- | --- |
| AWS region | `us-east-1` | Confirm at kickoff |
| VPC CIDR | `10.10.0.0/16` | |
| Public subnet | `10.10.1.0/24` | WAF instance and NAT Gateway, routes to the Internet Gateway |
| Private subnet | `10.10.2.0/24` | Juice Shop and Wazuh, outbound via NAT Gateway |
| Name prefix | `lab-cloudsec-` | e.g. `lab-cloudsec-vpc` |

## Instances

| Name tag | Subnet | Private IP | Public IP | Role |
| --- | --- | --- | --- | --- |
| `vm-waf` | Public | 10.10.1.10 | Elastic IP | ModSecurity + OWASP CRS reverse proxy, SSH jump host |
| `vm-juiceshop` | Private | 10.10.2.10 | No | Juice Shop in Docker |
| `vm-wazuh` | Private | 10.10.2.20 | No | Wazuh server, at least 8 GB RAM |

## Allowed traffic (security groups)

| From | To | Port | Purpose |
| --- | --- | --- | --- |
| Internet | `vm-waf` | 80, 443 | Users and attackers reach the app through the WAF |
| Team IPs | `vm-waf` | 22 | SSH administration and jump host |
| `vm-waf` | `vm-juiceshop` | 3000 | Proxy to Juice Shop |
| `vm-waf` | `vm-juiceshop`, `vm-wazuh` | 22 | SSH through the jump host |
| `vm-waf`, `vm-juiceshop` | `vm-wazuh` | 1514, 1515 | Wazuh agent traffic and enrolment |
| `vm-waf` (SSH tunnel) | `vm-wazuh` | 443 | Wazuh dashboard |

## Network module outputs (available now)

- `vpc_id`
- `public_subnet_id`, `private_subnet_id`
- `security_group_ids` (map: `waf`, `juiceshop`, `wazuh`)

## Compute module outputs (T07, needed by Ansible)

- `waf_public_ip`
- `private_ips` (map of instance name to private IP)
- Generated file `ansible/inventory.ini`
- SSH user: `ubuntu`
