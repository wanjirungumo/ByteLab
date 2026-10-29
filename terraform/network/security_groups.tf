# ---------------------------------------------------------------------------
# Security groups — one per instance, rules from docs/interfaces.md
# Rules between instances reference the other security group, not IPs.
# ---------------------------------------------------------------------------

resource "aws_security_group" "waf" {
  name        = "${var.project_name}-waf-sg"
  description = "WAF reverse proxy: public web traffic, SSH from the team"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-waf-sg" }
}

resource "aws_security_group" "juiceshop" {
  name        = "${var.project_name}-juiceshop-sg"
  description = "Juice Shop: reachable only from the WAF"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-juiceshop-sg" }
}

resource "aws_security_group" "wazuh" {
  name        = "${var.project_name}-wazuh-sg"
  description = "Wazuh SIEM: agents from WAF and Juice Shop, admin via the WAF jump host"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-wazuh-sg" }
}

# --- WAF ---------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "waf_http" {
  security_group_id = aws_security_group.waf.id
  description       = "HTTP from the Internet (users and attackers)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "waf_https" {
  security_group_id = aws_security_group.waf.id
  description       = "HTTPS from the Internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "waf_ssh" {
  for_each = toset(var.admin_cidrs)

  security_group_id = aws_security_group.waf.id
  description       = "SSH from team IP ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

# --- Juice Shop --------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "juiceshop_app" {
  security_group_id            = aws_security_group.juiceshop.id
  description                  = "Juice Shop app, only from the WAF"
  referenced_security_group_id = aws_security_group.waf.id
  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
}

resource "aws_vpc_security_group_ingress_rule" "juiceshop_ssh" {
  security_group_id            = aws_security_group.juiceshop.id
  description                  = "SSH via the WAF jump host"
  referenced_security_group_id = aws_security_group.waf.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

# --- Wazuh -------------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "wazuh_agents" {
  for_each = {
    waf_1514       = { sg = aws_security_group.waf.id, port = 1514 }
    waf_1515       = { sg = aws_security_group.waf.id, port = 1515 }
    juiceshop_1514 = { sg = aws_security_group.juiceshop.id, port = 1514 }
    juiceshop_1515 = { sg = aws_security_group.juiceshop.id, port = 1515 }
  }

  security_group_id            = aws_security_group.wazuh.id
  description                  = "Wazuh agent traffic (${each.key})"
  referenced_security_group_id = each.value.sg
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
}

resource "aws_vpc_security_group_ingress_rule" "wazuh_dashboard" {
  security_group_id            = aws_security_group.wazuh.id
  description                  = "Wazuh dashboard via SSH tunnel through the WAF"
  referenced_security_group_id = aws_security_group.waf.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "wazuh_ssh" {
  security_group_id            = aws_security_group.wazuh.id
  description                  = "SSH via the WAF jump host"
  referenced_security_group_id = aws_security_group.waf.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

# --- Outbound ----------------------------------------------------------------
# All instances may go out (package installs, Docker images, Wazuh traffic).
# Checkov will flag this: document it as an accepted risk or narrow it later.

resource "aws_vpc_security_group_egress_rule" "all_out" {
  for_each = {
    waf       = aws_security_group.waf.id
    juiceshop = aws_security_group.juiceshop.id
    wazuh     = aws_security_group.wazuh.id
  }

  security_group_id = each.value
  description       = "All outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
