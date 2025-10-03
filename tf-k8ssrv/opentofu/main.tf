provider "azurerm" {
  features {}
}
// Determine principals list: use provided principal_ids or default to current principal
data "azurerm_client_config" "current" {}

// Ensure principals is a map of friendly_id => principal_object_id
locals {
  principals_map = length(var.principal_ids) > 0 ? var.principal_ids : { self = data.azurerm_client_config.current.object_id }
}

// Instantiate the vm module once per principal id. Each module creates its own resource group.
module "vm" {
  for_each = local.principals_map

  source = "./modules/vm"

  # Build VM name by concatenating base and friendly id (the module expects full vm_name)
  vm_name             = "${var.vm_base_name}${each.key}"
  # Build resource group name as "rg<vm_name>" and pass it to module
  resource_group_name = "rg${var.vm_base_name}${each.key}"
  location            = var.location
  principal_id        = each.value
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  tags                = var.tags
  allowed_cidr        = var.allowed_cidr
  shutdown_daily_recurrence_time = var.shutdown_daily_recurrence_time
  shutdown_time_zone             = var.shutdown_time_zone
}
