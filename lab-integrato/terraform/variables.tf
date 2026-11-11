variable "aws_region" {
  description = "Region. Learner Lab consente solo us-east-1 e us-west-2."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.aws_region)
    error_message = "Learner Lab: usare us-east-1 o us-west-2."
  }
}

variable "project_name" {
  description = "Prefisso nomi risorse e tag."
  type        = string
  default     = "soclab"
}

variable "availability_zone" {
  description = "AZ unica del lab. null = prima AZ disponibile."
  type        = string
  default     = null
}

# ---------- Accesso ----------
variable "allowed_cidrs" {
  description = "CIDR (offens, defens, docenti) che raggiungono il WAF su 80/443. Es: [\"203.0.113.10/32\"]. Mai 0.0.0.0/0."
  type        = list(string)

  validation {
    condition     = length(var.allowed_cidrs) > 0 && alltrue([for c in var.allowed_cidrs : can(cidrhost(c, 0)) && c != "0.0.0.0/0"])
    error_message = "allowed_cidrs: lista non vuota di CIDR validi, 0.0.0.0/0 vietato."
  }
}

variable "admin_cidrs" {
  description = "CIDR che possono fare SSH sul WAF/jump host (gruppo cloud e defens). Mai 0.0.0.0/0."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0 && alltrue([for c in var.admin_cidrs : can(cidrhost(c, 0)) && c != "0.0.0.0/0"])
    error_message = "admin_cidrs: lista non vuota di CIDR validi, 0.0.0.0/0 vietato."
  }
}

# ---------- Rete ----------
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "enable_nat_gateway" {
  description = "NAT GW per le VM private (apt, docker pull, Wazuh). Costa ~1 USD/giorno anche a VM spente: destroy a fine uso."
  type        = bool
  default     = true
}

# ---------- Compute ----------
variable "instance_profile_name" {
  description = "Instance profile esistente. Learner Lab: LabInstanceProfile. null = nessuno."
  type        = string
  default     = "LabInstanceProfile"
}

variable "waf_instance_type" {
  type    = string
  default = "t3.small"
}

variable "juice_instance_type" {
  type    = string
  default = "t3.small"
}

variable "wazuh_instance_type" {
  description = "Wazuh all-in-one: minimo 4 GB RAM, consigliato 8 GB."
  type        = string
  default     = "t3.large"
}

variable "waf_volume_gb" {
  type    = number
  default = 20
}

variable "juice_volume_gb" {
  type    = number
  default = 20
}

variable "wazuh_volume_gb" {
  type    = number
  default = 50
}

# ---------- Parametri passati ad Ansible ----------
variable "waf_mode" {
  description = "off = reverse proxy senza regole (fase offens); detection = logga; blocking = blocca (fase difesa). Cambia solo il file generato per Ansible: rieseguire Ansible."
  type        = string
  default     = "off"

  validation {
    condition     = contains(["off", "detection", "blocking"], var.waf_mode)
    error_message = "waf_mode: off, detection o blocking."
  }
}

variable "wazuh_version" {
  description = "Versione Wazuh da installare. Verificare compatibilita con Ubuntu 22.04."
  type        = string
  default     = "4.9"
}

variable "juice_shop_port" {
  type    = number
  default = 3000
}
