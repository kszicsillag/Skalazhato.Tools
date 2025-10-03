variable "resource_group_base" {
  type        = string
  description = "Base name for resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "principal_id" {
  type        = string
  description = "Principal object id for which to create the VM"
}

variable "vm_name" {
  type        = string
}

variable "vm_size" {
  type        = string
}

variable "admin_username" {
  type        = string
}

variable "ssh_public_key_path" {
  type        = string
}

variable "tags" {
  type        = map(string)
}

variable "allowed_cidr" {
  type = string
}
