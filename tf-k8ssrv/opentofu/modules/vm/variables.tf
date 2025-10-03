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

variable "image_urn" {
  type        = string
  description = "Optional image URN in the form publisher:offer:sku:version. If provided, module will use it to set source_image_reference."
  default     = ""
}

// Validate URN format if provided

variable "enable_ansible_pull" {
  type        = bool
  description = "If true, Terraform will SSH to the VM and run ansible-pull to pull configuration from a git repo."
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

Branch and playbook_path are optional. If omitted, branch defaults to 'main' and playbook defaults to 'site.yml'. Use an empty string to disable.
EOT
  default     = ""
}


variable "ssh_private_key" {
  type        = string
  description = "Private SSH key used to SSH to the VM for provisioning (sensitive)."
  default     = ""
}

variable "ansible_oncalendar" {
  type        = string
  description = "systemd OnCalendar schedule string for ansible-pull (e.g. 'hourly', 'daily', or a full OnCalendar expression)."
  default     = "hourly"
}
variable "_image_urn_validation" {
  type    = any
  default = null
  validation {
    condition     = var.image_urn == "" || length(split(":", var.image_urn)) == 4
    error_message = "image_urn must be empty or in the form publisher:offer:sku:version"
  }
}



