# ---------------------------------------------------------------------------
# Root module -- the "infrastructure plane".
#
# In a bank, resource blocks here would CREATE the VMs/networks and their state
# would live in HCP Terraform. For this lab we take the existing fleet as input
# and produce the artifact Ansible consumes: a per-environment inventory file.
#
# This makes the Terraform -> Ansible handoff explicit and inspectable.
# ---------------------------------------------------------------------------

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/generated/${var.environment}-hosts.ini"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    environment                  = var.environment
    fleet                        = var.fleet
    ansible_user                 = var.ansible_user
    ansible_ssh_private_key_file = var.ansible_ssh_private_key_file
  })
}
