provider "azurerm" {
  features {}
  # Allow overriding subscription via variable (empty => provider will attempt to infer via az login or ARM_SUBSCRIPTION_ID)
  subscription_id = var.subscription_id
}
// Determine principals list: use provided principal_ids or default to current principal
data "azurerm_client_config" "current" {}

// Ensure principals is a map of friendly_id => principal_object_id
locals {
  principals_map = length(var.principal_ids) > 0 ? var.principal_ids : { (var.default_principal_friendly_id) = data.azurerm_client_config.current.object_id }
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
  ssh_public_key      = data.azurerm_key_vault_secret.ssh_pubkey_data.value
  image_urn           = var.image_urn
  enable_ansible_pull = var.enable_ansible_pull
  ansible_playbook_url = var.ansible_playbook_url
  ssh_private_key     = tls_private_key.generated_ssh.private_key_pem
  ansible_oncalendar  = var.ansible_oncalendar
  tags                = var.tags
  allowed_cidr        = var.allowed_cidr
  shutdown_daily_recurrence_time = var.shutdown_daily_recurrence_time
  shutdown_time_zone             = var.shutdown_time_zone
}

// Key Vault to hold shared secrets (in resource group 'Generic')
resource "azurerm_resource_group" "generic_rg" {
  name     = "Generic"
  location = var.location
}

// Generate SSH keypair locally (tls provider) and store public key in Key Vault
resource "tls_private_key" "generated_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault" "generic_kv" {
  name                        = var.key_vault_name != "" ? var.key_vault_name : "kvau-${var.vm_base_name}"
  location                    = azurerm_resource_group.generic_rg.location
  resource_group_name         = azurerm_resource_group.generic_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
}

// Store the SSH public key as a secret so module VMs can read it
resource "azurerm_key_vault_secret" "ssh_pubkey" {
  name         = "ssh-public-key"
  value        = tls_private_key.generated_ssh.public_key_openssh
  key_vault_id = azurerm_key_vault.generic_kv.id
}

// Data source to read the secret (module will get value from this data source)
data "azurerm_key_vault_secret" "ssh_pubkey_data" {
  name         = azurerm_key_vault_secret.ssh_pubkey.name
  key_vault_id = azurerm_key_vault.generic_kv.id
}

// Use RBAC to grant the current principal Key Vault Administrator permissions
data "azurerm_subscription" "current" {}

data "azurerm_role_definition" "kv_admin" {
  name  = "Key Vault Administrator"
  scope = data.azurerm_subscription.current.id
}

resource "random_uuid" "kv_role_assignment" {}

resource "azurerm_role_assignment" "kv_admin_assignment" {
  scope              = azurerm_key_vault.generic_kv.id
  role_definition_id = data.azurerm_role_definition.kv_admin.id
  principal_id       = data.azurerm_client_config.current.object_id
  name               = random_uuid.kv_role_assignment.result
}

// Private key is NOT written to local disk by default. Keep private keys secure and retrieve from a secure store if needed.

