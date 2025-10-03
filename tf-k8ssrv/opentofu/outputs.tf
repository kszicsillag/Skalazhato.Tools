output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}

output "vm_names" {
  value = { for k, v in azurerm_linux_virtual_machine.vm : k => v.name }
}

output "vm_private_ips" {
  value = { for k, v in azurerm_network_interface.nic : k => v.private_ip_address }
}

output "vm_public_ips" {
  value = { for k, v in azurerm_public_ip.vm_public_ip : k => v.ip_address }
}

output "allowed_cidr" {
  value = var.allowed_cidr
}
