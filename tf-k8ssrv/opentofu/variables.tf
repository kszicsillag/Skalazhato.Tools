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
variable "vm_base_name" {
  type        = string
  description = "Base name for the VM. The friendly id will be appended to form the final VM name"
  default     = "viaumb11-lnxvm00-"
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
  type        = map(string)
  description = "Map of friendly id => principal object id. Example: { alice = "<objid1>", bob = "<objid2>" }. If empty defaults to { self = <current principal> }"
  default     = {}
}

variable "shutdown_daily_recurrence_time" {
  type        = string
  description = "Daily recurrence time for auto-shutdown in HHmm format, e.g. '0100'"
  default     = "0100"
}

variable "shutdown_time_zone" {
  type        = string
  description = "Time zone for auto-shutdown (Windows time zone name), e.g. 'UTC' or 'W. Europe Standard Time'"
  default     = "UTC"
}
