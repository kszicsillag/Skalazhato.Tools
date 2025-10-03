variable "location" {
  type        = string
  description = "Azure region to deploy into"
  default     = "northeurope"
}
variable "vm_base_name" {
  type        = string
  description = "Base name for the VM. The friendly id will be appended to form the final VM name"
  default     = "viaumb11-lnxvm-"
}

variable "vm_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_D2als_v6"
}

variable "image_urn" {
  type        = string
  description = "Optional image URN in the form publisher:offer:sku:version. Defaults to Canonical Ubuntu 24.04 LTS."
  default     = "Canonical:UbuntuServer:24_04-lts:latest"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
  default     = "azureuser"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
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
