output "inventory_path" {
  description = "Path to the generated Ansible inventory for this environment."
  value       = local_file.ansible_inventory.filename
}

output "host_count" {
  description = "Number of managed hosts in the fleet."
  value       = sum([for group, hosts in var.fleet : length(hosts)])
}

output "inventory_content" {
  description = "Rendered inventory content (also written to disk)."
  value       = local_file.ansible_inventory.content
}
