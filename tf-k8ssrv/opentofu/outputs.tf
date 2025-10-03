output "resource_group_names" {
  value = { for k, m in module.vm : k => m.resource_group_name }
}

output "vm_names" {
  value = { for k, m in module.vm : k => m.vm_name }
}

output "vm_private_ips" {
  value = { for k, m in module.vm : k => m.vm_private_ip }
}

output "vm_public_ips" {
  value = { for k, m in module.vm : k => m.vm_public_ip }
}

output "allowed_cidr" {
  value = var.allowed_cidr
}
