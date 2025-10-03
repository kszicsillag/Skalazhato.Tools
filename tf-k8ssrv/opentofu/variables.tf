variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create"
  default     = "devtestlab"
}

variable "location" {
  type        = string
  description = "Azure region to deploy into"
  default     = "northeurope"
}

variable "lab_name" {
  type        = string
  description = "DevTest Lab name"
  default     = "dtlab-viaumb11"
}

variable "vm_name" {
  type        = string
  description = "Name of the Linux VM"
  default     = "viaumb11-lnxvm00"
}

variable "vm_size" {
  type        = string
  description = "Size of the VM"
  default     = "d2als-v6"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to public SSH key to provision for the VM"
  default     = "~/.ssh/id_rsa.pub"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = { project = "opentofu-demo" }
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR range allowed to access the VM public IP (SSH). Example: 203.0.113.0/24"
  default     = "0.0.0.0/0"
}

variable "principal_ids" {
  type        = list(string)
  description = "List of principal object IDs (users/service principals) to create VMs for and assign VM login role. If empty, defaults to the principal running Terraform."
  default     = []
}
