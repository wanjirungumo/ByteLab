# Genera inventario e variabili per Ansible (terraform/ansible/, gitignored).

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/ansible/inventory.ini"
  file_permission = "0644"
  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    waf_public_ip   = aws_eip.waf.public_ip
    juice_private   = local.juice_ip
    wazuh_private   = local.wazuh_ip
    key_path        = abspath(local_sensitive_file.ssh_key.filename)
  })
}

resource "local_sensitive_file" "ansible_vars" {
  filename        = "${path.module}/ansible/group_vars/all/terraform_generated.yml"
  file_permission = "0600"
  content = templatefile("${path.module}/templates/lab_vars.yml.tftpl", {
    project_name         = var.project_name
    waf_mode             = var.waf_mode
    waf_public_ip        = aws_eip.waf.public_ip
    waf_private_ip       = local.waf_private_ip
    juice_ip             = local.juice_ip
    juice_port           = var.juice_shop_port
    wazuh_ip             = local.wazuh_ip
    wazuh_version        = var.wazuh_version
    wazuh_admin_password = random_password.wazuh_admin.result
  })
}
