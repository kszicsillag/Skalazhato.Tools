k3s Ansible playbook
====================

Simple Ansible playbook to install k3s on a VM. It's intended to be used with the terraform module's ansible-pull runner (see opentofu/modules/vm).

Usage
-----

The playbook runs on localhost (connection: local) and is intended for single-node k3s server installs only.

This playbook does not support agent mode or joining multiple nodes; it's optimized for bootstrapping a single server node.

Example variables (can be passed via ansible-pull extra-vars or rendered in your repo):

- k3s_version: "latest"         # or an explicit version like 'v1.27.4+k3s1'
- k3s_channel: "stable"
- k3s_token: "<pre-shared-token>"   # optional for single-node installs

Notes
-----

- The playbook uses the official k3s install script (https://get.k3s.io). For production or air-gapped installs consider using a vetted package or offline installation method.
- The server writes kubeconfig to /etc/rancher/k3s/k3s.yaml with 0644 so tools can access it on the machine.
- The playbook is minimal by design — feel free to extend with networking/CNI, ingress, and other components.

Integration with terraform
-------------------------

Set `ansible_playbook_url` in the terraform module to point at the repo and path. Example (this repository):

https://github.com/kszicsillag/Skalazhato.Tools.git#main#opentofu/ansible/k3s/site.yml
