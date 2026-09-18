variable "environment" {
  description = "Deployment environment (dev, qa, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}

variable "ansible_user" {
  description = "SSH user Ansible uses to reach the hosts."
  type        = string
  default     = "vms"
}

variable "ansible_ssh_private_key_file" {
  description = "Path to the private key Ansible uses."
  type        = string
  default     = "~/.ssh/vms-ai"
}

variable "fleet" {
  description = <<-EOT
    The infrastructure inventory, grouped by tier. In a real deployment these
    hosts would be the RESULT of resource creation (libvirt_domain,
    aws_instance, ...) and their IPs would come from resource attributes. Here
    we model the existing home-lab VMs so Terraform can render the inventory.
  EOT
  type = map(list(object({
    name = string
    ip   = string
  })))
  default = {
    app = [
      { name = "app01", ip = "192.168.122.203" }
    ]
    database = [
      { name = "db01", ip = "192.168.122.204" }
    ]
  }
}
