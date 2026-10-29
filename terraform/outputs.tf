output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_id" {
  value = module.network.public_subnet_id
}

output "private_subnet_id" {
  value = module.network.private_subnet_id
}

output "security_group_ids" {
  value = module.network.security_group_ids
}

output "nat_gateway_public_ip" {
  value = module.network.nat_gateway_public_ip
}
