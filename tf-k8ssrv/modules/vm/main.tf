// Module: vm
// Creates a resource group, vnet, subnet, nsg, public ip, nic, linux vm, AAD extension and role assignment

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

locals {
  image_parts = var.image_urn != "" ? split(":", var.image_urn) : []
}

locals {
  image_publisher = var.image_urn != "" ? local.image_parts[0] : "Canonical"
  image_offer     = var.image_urn != "" ? local.image_parts[1] : "UbuntuServer"
  image_sku       = var.image_urn != "" ? local.image_parts[2] : "24_04-lts"
  image_version   = var.image_urn != "" ? local.image_parts[3] : "latest"
}

// Parse ansible_playbook_url into repo, branch, and playbook path.
// Format: <repo_url>#<branch>#<playbook_path>
locals {
  ansible_parts = var.ansible_playbook_url != "" ? split("#", var.ansible_playbook_url) : []
  ansible_repo  = length(local.ansible_parts) >= 1 && local.ansible_parts[0] != "" ? local.ansible_parts[0] : ""
  ansible_branch = length(local.ansible_parts) >= 2 && local.ansible_parts[1] != "" ? local.ansible_parts[1] : "main"
  ansible_playbook_path = length(local.ansible_parts) >= 3 && local.ansible_parts[2] != "" ? local.ansible_parts[2] : "site.yml"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

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

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.vm_name}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
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
  name                = var.vm_name
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
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Use provided image URN parts when set; otherwise fall back to Ubuntu 24.04 LTS
  source_image_reference {
    publisher = local.image_publisher
    offer     = local.image_offer
    sku       = local.image_sku
    version   = local.image_version
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "aadlogin" {
  name                 = "AADSSHLoginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0.3162.1"

  // The extension does not require custom settings for default behaviour
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

// Auto-shutdown schedule for the VM (applies to VMs not in DevTest Lab)
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
  location                = azurerm_resource_group.rg.location
  virtual_machine_id      = azurerm_linux_virtual_machine.vm.id
  // daily recurrence time in HHmm (example '0100') and timezone
  daily_recurrence_time   = var.shutdown_daily_recurrence_time
  timezone                = var.shutdown_time_zone

  enabled = true

  notification_settings {
    enabled = false
  }
}

// Optional ansible-pull provisioner executed from Terraform controller to the VM
resource "null_resource" "ansible_pull" {
  count = var.enable_ansible_pull ? 1 : 0

  depends_on = [azurerm_linux_virtual_machine.vm, azurerm_public_ip.vm_public_ip]

  provisioner "file" {
    content     = templatefile("${path.module}/scripts/bin/ansible-pull-runner.sh.tpl", {
      ansible_repo         = local.ansible_repo,
      ansible_branch       = local.ansible_branch,
      ansible_playbook_path = local.ansible_playbook_path
    })
    destination = "/tmp/ansible-pull-runner.sh"

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.vm_public_ip.ip_address
      user        = var.admin_username
      private_key = var.ssh_private_key
      timeout     = "2m"
    }
  }

  provisioner "file" {
    content     = templatefile("${path.module}/scripts/systemd/ansible-pull.service.tpl", {})
    destination = "/tmp/ansible-pull.service"

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.vm_public_ip.ip_address
      user        = var.admin_username
      private_key = var.ssh_private_key
      timeout     = "2m"
    }
  }

  provisioner "file" {
    content     = templatefile("${path.module}/scripts/systemd/ansible-pull.timer.tpl", { ansible_oncalendar = var.ansible_oncalendar })
    destination = "/tmp/ansible-pull.timer"

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.vm_public_ip.ip_address
      user        = var.admin_username
      private_key = var.ssh_private_key
      timeout     = "2m"
    }
  }

  provisioner "remote-exec" {
    inline = split("\n", trimspace(templatefile("${path.module}/scripts/provision/ansible-pull-setup.tpl", {
      ansible_oncalendar   = var.ansible_oncalendar,
      ansible_repo         = local.ansible_repo,
      ansible_branch       = local.ansible_branch,
      ansible_playbook_path = local.ansible_playbook_path
    })))

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.vm_public_ip.ip_address
      user        = var.admin_username
      private_key = var.ssh_private_key
      timeout     = "2m"
    }
  }
}
