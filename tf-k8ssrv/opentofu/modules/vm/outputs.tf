output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.vm_public_ip.ip_address
}

output "vm_private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
