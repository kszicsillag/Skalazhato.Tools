provider "azurerm" {
  features {}
}
// Determine principals list: use provided principal_ids or default to current principal
data "azurerm_client_config" "current" {}

locals {
  principals = length(var.principal_ids) > 0 ? var.principal_ids : [data.azurerm_client_config.current.object_id]
}

// Instantiate the vm module once per principal id. Each module creates its own resource group
module "vm" {
  for_each = { for p in local.principals : p => p }

  source = "./modules/vm"

  resource_group_base = var.resource_group_name
  location            = var.location
  principal_id        = each.key
  vm_name             = var.vm_name
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  tags                = var.tags
  allowed_cidr        = var.allowed_cidr
}
