# ---------- Credenziali generate ----------
locals {
  juice_user_data = <<-EOF
    #!/bin/bash
    set -eux
    until apt-get update; do sleep 5; done
    apt-get install -y docker.io
    systemctl enable --now docker
    docker run -d --restart unless-stopped --name juice-shop -p ${var.juice_shop_port}:3000 bkimminich/juice-shop
  EOF

  waf_user_data = <<-EOF
    #!/bin/bash
    set -eux
    until apt-get update; do sleep 5; done
    apt-get install -y nginx
    cat > /etc/nginx/sites-available/default <<'NGINX'
    server {
      listen 80 default_server;
      location / {
        proxy_pass http://${local.juice_ip}:${var.juice_shop_port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      }
    }
    NGINX
    systemctl restart nginx
  EOF
}

resource "tls_private_key" "lab" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "lab" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.lab.public_key_openssh
}

# Chiave privata salvata in locale (gitignored). Nello state in chiaro.
resource "local_sensitive_file" "ssh_key" {
  filename        = "${path.module}/generated/${var.project_name}.pem"
  content         = tls_private_key.lab.private_key_openssh
  file_permission = "0600"
}

# Caratteri speciali ammessi dall'installer Wazuh: . * + ? -
resource "random_password" "wazuh_admin" {
  length           = 20
  special          = true
  override_special = ".*+?-"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# ---------- VM ----------
resource "aws_instance" "waf" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.waf_instance_type
  subnet_id                   = aws_subnet.public.id
  private_ip                  = local.waf_private_ip
  vpc_security_group_ids      = [aws_security_group.waf.id]
  key_name                    = aws_key_pair.lab.key_name
  iam_instance_profile        = var.instance_profile_name
  ebs_optimized               = true
  monitoring                  = false
  user_data                   = replace(local.waf_user_data, "\r", "")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.waf_volume_gb
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${var.project_name}-waf", Role = "waf" }

  lifecycle {
    ignore_changes = [ami] # evita ricreazione se esce una AMI nuova durante il lab
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_instance" "juice" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.juice_instance_type
  subnet_id                   = aws_subnet.private.id
  private_ip                  = local.juice_ip
  vpc_security_group_ids      = [aws_security_group.juice.id]
  key_name                    = aws_key_pair.lab.key_name
  iam_instance_profile        = var.instance_profile_name
  ebs_optimized               = true
  monitoring                  = false
  user_data                   = replace(local.juice_user_data, "\r", "")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.juice_volume_gb
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${var.project_name}-juice-shop", Role = "target" }

  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [aws_route.private_default]
}

resource "aws_instance" "wazuh" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.wazuh_instance_type
  subnet_id              = aws_subnet.private.id
  private_ip             = local.wazuh_ip
  vpc_security_group_ids = [aws_security_group.wazuh.id]
  key_name               = aws_key_pair.lab.key_name
  iam_instance_profile   = var.instance_profile_name
  ebs_optimized          = true
  monitoring             = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.wazuh_volume_gb
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${var.project_name}-wazuh", Role = "siem" }

  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [aws_route.private_default]
}

# EIP unico: IP pubblico stabile del WAF anche dopo stop/start.
resource "aws_eip" "waf" {
  domain     = "vpc"
  instance   = aws_instance.waf.id
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "${var.project_name}-waf-eip" }
}
