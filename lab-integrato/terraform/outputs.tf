output "region" {
  value = var.aws_region
}

output "waf_public_ip" {
  description = "Unico IP pubblico del lab (EIP del WAF)."
  value       = aws_eip.waf.public_ip
}

output "juice_shop_url" {
  description = "URL per offens (stesso URL prima e dopo l'attivazione del WAF)."
  value       = "http://${aws_eip.waf.public_ip}"
}

output "private_ips" {
  value = {
    waf   = local.waf_private_ip
    juice = local.juice_ip
    wazuh = local.wazuh_ip
  }
}

output "ssh_waf" {
  value = "ssh -i ${abspath(local_sensitive_file.ssh_key.filename)} ubuntu@${aws_eip.waf.public_ip}"
}

output "ssh_juice" {
  value = "ssh -i ${abspath(local_sensitive_file.ssh_key.filename)} -J ubuntu@${aws_eip.waf.public_ip} ubuntu@${local.juice_ip}"
}

output "ssh_wazuh" {
  value = "ssh -i ${abspath(local_sensitive_file.ssh_key.filename)} -J ubuntu@${aws_eip.waf.public_ip} ubuntu@${local.wazuh_ip}"
}

output "wazuh_dashboard_tunnel" {
  description = "Tunnel per la dashboard Wazuh, poi aprire https://localhost:8443"
  value       = "ssh -i ${abspath(local_sensitive_file.ssh_key.filename)} -L 8443:${local.wazuh_ip}:443 ubuntu@${aws_eip.waf.public_ip}"
}

output "wazuh_admin_password" {
  description = "terraform output -raw wazuh_admin_password"
  value       = random_password.wazuh_admin.result
  sensitive   = true
}

output "ssh_key_file" {
  value = abspath(local_sensitive_file.ssh_key.filename)
}

output "instance_ids" {
  description = "Per stop/start: make stop / make start"
  value       = join(" ", [aws_instance.waf.id, aws_instance.juice.id, aws_instance.wazuh.id])
}
