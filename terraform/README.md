# terraform/ — the provisioning plane

Renders a per-environment Ansible inventory from the `fleet` variable, modeling
the **Terraform → Ansible handoff**. State is local by default; switch to HCP
Terraform via the `cloud` block in `versions.tf` (see
[../docs/03-hcp-terraform-setup.md](../docs/03-hcp-terraform-setup.md)).

## Local run

```bash
cd terraform
terraform init -backend=false
terraform apply -var environment=dev
cat generated/dev-hosts.ini          # the handoff artifact
```

## Making it real

Replace the `local_file` resource with actual infrastructure and read IPs back
from resource attributes:

```hcl
# Example: libvirt (dmacvicar/libvirt) to manage the home-lab VMs for real, or
# aws_instance / azurerm_linux_virtual_machine in cloud. The fleet map would
# then be built from resource outputs instead of hardcoded IPs.
```

> Do **not** point a `libvirt` provider at your existing `virt-manager` VMs
> without `terraform import` first — an apply would try to recreate them.
