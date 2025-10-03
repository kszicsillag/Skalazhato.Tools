// Module: vm
// Creates a resource group, vnet, subnet, nsg, public ip, nic, linux vm, AAD extension and role assignment

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_base}-${substr(var.principal_id,0,6)}"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_base}-${substr(var.principal_id,0,6)}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_group_base}-${substr(var.principal_id,0,6)}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name}-${substr(var.principal_id,0,6)}-nsg"
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

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.vm_name}-${substr(var.principal_id,0,6)}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-${substr(var.principal_id,0,6)}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.vm_name}-${substr(var.principal_id,0,6)}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.nic.id]

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

resource "azurerm_virtual_machine_extension" "aadlogin" {
  name                 = "AADLoginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForLinux"
  type_handler_version = "1.0"

  settings = jsonencode({})

  protected_settings = jsonencode({})
}

data "azurerm_subscription" "current" {}

data "azurerm_role_definition" "vm_user_login" {
  name  = "Virtual Machine User Login"
  scope = data.azurerm_subscription.current.id
}

resource "random_uuid" "role_assignment" {}

resource "azurerm_role_assignment" "tf_vm_login" {
  scope              = azurerm_linux_virtual_machine.vm.id
  role_definition_id = data.azurerm_role_definition.vm_user_login.id
  principal_id       = var.principal_id
  depends_on         = [azurerm_virtual_machine_extension.aadlogin]
  name               = random_uuid.role_assignment.result
}
