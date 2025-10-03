provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Determine principals list: use provided principal_ids or default to current principal
data "azurerm_client_config" "current" {}

locals {
  principals = length(var.principal_ids) > 0 ? var.principal_ids : [data.azurerm_client_config.current.object_id]
}

# Create a virtual network and subnet to host the VM
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "vm_public_ip" {
  for_each            = { for p in local.principals : p => p }
  name                = "${var.vm_name}-${substr(each.key,0,6)}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  for_each            = { for p in local.principals : p => p }
  name                = "${var.vm_name}-${substr(each.key,0,6)}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip[each.key].id
  }

}

# Public IP for the VM
/* public_ip created per principal above */

# Network Security Group restricting SSH to allowed_cidr
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_SSH_From_AllowedCIDR"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny_SSH_Others"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate the NSG with the subnet (separate resource to avoid provider attribute mismatch)
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each            = { for p in local.principals : p => p }
  name                = "${var.vm_name}-${substr(each.key,0,6)}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.nic[each.key].id]

  # Enable system assigned identity so the VM can be granted Azure AD related roles if needed
  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "24_04-lts"
    version   = "latest"
  }

  tags = var.tags
}

# Install the AADLoginForLinux extension to enable Azure AD (Entra) login
resource "azurerm_virtual_machine_extension" "aadlogin" {
  for_each             = { for p in local.principals : p => p }
  name                 = "AADLoginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm[each.key].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForLinux"
  type_handler_version = "1.0"

  settings = jsonencode({})

  protected_settings = jsonencode({})
}

# Grant the Terraform-running principal the VM login role on the VM so they can SSH via Entra
data "azurerm_client_config" "current" {}

# Current subscription for scoping built-in role lookup
data "azurerm_subscription" "current" {}

# Use built-in role "Virtual Machine User Login" scoped to current subscription
data "azurerm_role_definition" "vm_user_login" {
  name  = "Virtual Machine User Login"
  scope = data.azurerm_subscription.current.id
}

resource "random_uuid" "role_assignment" {
  for_each = { for p in local.principals : p => p }
}

resource "azurerm_role_assignment" "tf_vm_login" {
  for_each           = { for p in local.principals : p => p }
  scope              = azurerm_linux_virtual_machine.vm[each.key].id
  role_definition_id = data.azurerm_role_definition.vm_user_login.id
  principal_id       = each.key
  depends_on         = [azurerm_virtual_machine_extension.aadlogin]
  name               = random_uuid.role_assignment[each.key].result
}
