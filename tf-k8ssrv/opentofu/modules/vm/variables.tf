variable "location" {
  type        = string
  description = "Azure region"
}

variable "principal_id" {
  type        = string
  description = "Principal object id for which to create the VM"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create for this VM (passed in by root)"
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

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content (the module expects the public key text, e.g. from Key Vault)."
}

variable "tags" {
  type        = map(string)
}

variable "allowed_cidr" {
  type = string
}

variable "shutdown_time_zone" {
  type        = string
  description = "Time zone used for the auto-shutdown schedule. Example: 'UTC' or 'W. Europe Standard Time'"
  default     = "UTC"
}

variable "shutdown_daily_recurrence_time" {
  type        = string
  description = "Daily recurrence time in HHmm format, e.g. '0100' for 01:00"
  default     = "0100"
}



