# Modello di accesso:
#   Internet -> (allowed_cidrs) -> WAF :80/:443 -> Juice Shop :3000 (privata)
#   SSH: admin_cidrs -> WAF (jump host) -> VM private
#   Wazuh dashboard: solo via tunnel SSH attraverso il WAF (nessuna porta pubblica)
#   Agent Wazuh (WAF, Juice) -> Wazuh :1514/:1515

resource "aws_security_group" "waf" {
  name        = "${var.project_name}-waf"
  description = "WAF reverse proxy e jump host"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.project_name}-waf-sg" }
}

resource "aws_security_group" "juice" {
  name        = "${var.project_name}-juice"
  description = "Juice Shop target, raggiungibile solo dal WAF"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.project_name}-juice-sg" }
}

resource "aws_security_group" "wazuh" {
  name        = "${var.project_name}-wazuh"
  description = "Wazuh SIEM"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.project_name}-wazuh-sg" }
}

# ---------- WAF ----------
resource "aws_vpc_security_group_ingress_rule" "waf_http" {
  for_each          = toset(var.allowed_cidrs)
  security_group_id = aws_security_group.waf.id
  description       = "HTTP verso WAF"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "waf_https" {
  for_each          = toset(var.allowed_cidrs)
  security_group_id = aws_security_group.waf.id
  description       = "HTTPS verso WAF"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "waf_ssh" {
  for_each          = toset(var.admin_cidrs)
  security_group_id = aws_security_group.waf.id
  description       = "SSH admin"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

# ---------- Juice Shop ----------
resource "aws_vpc_security_group_ingress_rule" "juice_app" {
  security_group_id            = aws_security_group.juice.id
  description                  = "App da WAF"
  referenced_security_group_id = aws_security_group.waf.id
  ip_protocol                  = "tcp"
  from_port                    = var.juice_shop_port
  to_port                      = var.juice_shop_port
}

resource "aws_vpc_security_group_ingress_rule" "juice_ssh" {
  security_group_id            = aws_security_group.juice.id
  description                  = "SSH da jump host"
  referenced_security_group_id = aws_security_group.waf.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

# ---------- Wazuh ----------
locals {
  wazuh_ingress = {
    ssh_from_waf        = { sg = aws_security_group.waf.id, port = 22, desc = "SSH da jump host" }
    dash_from_waf       = { sg = aws_security_group.waf.id, port = 443, desc = "Dashboard via tunnel SSH" }
    agent_waf_events    = { sg = aws_security_group.waf.id, port = 1514, desc = "Eventi agent WAF" }
    agent_waf_enroll    = { sg = aws_security_group.waf.id, port = 1515, desc = "Enrollment agent WAF" }
    agent_juice_events  = { sg = aws_security_group.juice.id, port = 1514, desc = "Eventi agent Juice" }
    agent_juice_enroll  = { sg = aws_security_group.juice.id, port = 1515, desc = "Enrollment agent Juice" }
  }
}

resource "aws_vpc_security_group_ingress_rule" "wazuh" {
  for_each                     = local.wazuh_ingress
  security_group_id            = aws_security_group.wazuh.id
  description                  = each.value.desc
  referenced_security_group_id = each.value.sg
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
}

# ---------- Egress (apt, docker pull, installer Wazuh) ----------
resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = {
    waf   = aws_security_group.waf.id
    juice = aws_security_group.juice.id
    wazuh = aws_security_group.wazuh.id
  }

  security_group_id = each.value
  description       = "Egress verso Internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
