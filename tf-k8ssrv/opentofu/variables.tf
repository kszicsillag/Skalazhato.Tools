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

variable "default_principal_friendly_id" {
  type        = string
  description = "Friendly id key to use as the default when `principal_ids` is empty. Example: 'self' or 'admin'"
  default     = "000000"
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

variable "enable_ansible_pull" {
  type        = bool
  description = "Enable ansible-pull provisioning on created VMs (default false)."
  default     = false
}


variable "ansible_playbook_url" {
  type        = string
  description = <<-EOT
Single string that describes where to get the playbook for ansible-pull.
Format: <repo_url>#<branch>#<playbook_path>
Examples:
- "https://github.com/org/repo.git#main#site.yml"
- "git@github.com:org/repo.git#develop#playbooks/site.yml"

Branch and playbook_path are optional. If omitted, branch defaults to 'main' and playbook defaults to 'site.yml'.
EOT
  default     = ""
}


variable "ansible_oncalendar" {
  type        = string
  description = "systemd OnCalendar schedule string for ansible-pull (e.g. 'hourly', 'daily', or a full OnCalendar expression). If empty, defaults to 'hourly'."
  default     = ""
}
