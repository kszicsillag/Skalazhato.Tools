# OpenTofu (Terraform) demo: per-principal Linux VMs with Entra (Azure AD) login

This project now creates one Linux VM per principal object id in `var.principal_ids`. If `principal_ids` is empty the current principal running Terraform will get a single VM.

Features

- Creates a resource group, VNet and subnet
- Creates one VM per principal with a public IP (restricted by NSG to `var.allowed_cidr`)
- Each VM is created inside its own resource group named `${var.resource_group_name}-${short-principal-id}` so you can safely delete that RG without affecting other VMs.
- Enables Entra (Azure AD) login using the `AADLoginForLinux` VM extension
- Assigns each principal the `Virtual Machine User Login` role scoped to their VM so they can SSH via Entra

Prerequisites

- Azure CLI installed and logged in: `az login`
- Terraform (1.4+) or OpenTofu
- `azurerm` and `random` providers will be downloaded during `terraform init`
- The principal running Terraform needs permission to create role assignments (Owner or User Access Administrator) if you want Terraform to create the role assignment for other principals. Otherwise pre-create role assignments as an admin.

Quick start

1. Initialize the project:

   terraform init

2. Plan (example creating VMs for two principals):

   terraform plan -out plan.tfplan -var='principal_ids=["<objid1>","<objid2>"]' -var='allowed_cidr=203.0.113.0/24'

3. Apply:

   terraform apply "plan.tfplan"

Variables of interest

- `principal_ids` (list[string]) — list of principal object IDs to create VMs for. Defaults to `[current principal]` when empty.
- `allowed_cidr` (string) — CIDR that can reach the VM public IP on SSH. Default is `0.0.0.0/0` (change before apply!)
- `ssh_public_key_path` (string) — path to your public SSH key used during provisioning. Note: `file()` does not expand `~`; pass an absolute path or set this variable explicitly.
- `vm_size` — set to an SKU that exists in your region (you used `az vm list-skus -l northeurope` to inspect available SKUs).

Networking and access

- Each VM receives a `Standard` static public IP and is reachable only from `var.allowed_cidr` via NSG.
- NSG is associated at the subnet level in this configuration. If you need per-VM isolation, I can switch NSG association to NIC-level or create dedicated subnets per VM.

Entra (Azure AD) login notes

- The `AADLoginForLinux` extension is installed on each VM. Users require the `Virtual Machine User Login` or `Virtual Machine Administrator Login` role scoped to the VM to log in via Entra.
- Role assignments are created by Terraform for each principal in `principal_ids` (or the current principal if the list is empty). Ensure the Terraform principal has rights to create role assignments.

Outputs

- `vm_names` — map[principal_id] => VM name
- `vm_private_ips` — map[principal_id] => private IP
- `vm_public_ips` — map[principal_id] => public IP

The module implementation lives in `modules/vm/` — each instance creates a single VM and its dependencies. Outputs are returned as maps keyed by the principal id used as the module key.

Security notes

- Passwords or private keys must not be stored in state. This project uses SSH key material only for provisioning; the private key should remain local.
- If you use temporary passwords, be aware the generated secret will be in state unless stored/managed outside Terraform.

Next steps and optional improvements

- Add Azure Bastion for private access without opening SSH to the internet.
- Switch to dedicated subnets per-VM for stronger network isolation.
- Add a cleanup extension to remove the initial admin user once you confirm Entra login is working.

If you want, I can implement any of the optional improvements above.
