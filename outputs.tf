locals {
  vm_resources = {
    webserver          = proxmox_virtual_environment_vm.webserver
    postgres           = proxmox_virtual_environment_vm.postgres
    ansible_controller = proxmox_virtual_environment_vm.ansible
  }

  vm_addresses = {
    for vm_name, vm in local.vm_resources : vm_name => {
      lan_ipv4 = try([
        for address in flatten(vm.ipv4_addresses) : address
        if try(
          cidrhost("${address}/${local.lan_prefix_length}", 0) == cidrhost(var.lan_cidr, 0),
          false
        )
      ][0], null)

      tailscale_ipv4 = try(flatten([
        for index, interface_name in vm.network_interface_names :
        interface_name == "tailscale0" ? try(vm.ipv4_addresses[index], []) : []
      ])[0], null)
    }
  }

  vm_information = {
    for vm_name, vm in local.vm_resources : vm_name => {
      vm_id          = vm.vm_id
      name           = vm.name
      status         = vm.started ? "running" : "stopped"
      lan_ipv4       = local.vm_addresses[vm_name].lan_ipv4
      tailscale_ipv4 = local.vm_addresses[vm_name].tailscale_ipv4
      ssh_username   = var.ssh_username
      ssh_command = local.vm_addresses[vm_name].tailscale_ipv4 != null ? (
        "ssh ${var.ssh_username}@${local.vm_addresses[vm_name].tailscale_ipv4}"
        ) : local.vm_addresses[vm_name].lan_ipv4 != null ? (
        "ssh ${var.ssh_username}@${local.vm_addresses[vm_name].lan_ipv4}"
      ) : null
    }
  }
}

output "webserver_info" {
  description = "Webserver identity, configured start state (not runtime or guest health), Guest Agent IPs, and SSH details."
  value       = local.vm_information.webserver
}

output "postgres_info" {
  description = "PostgreSQL identity, configured start state (not runtime or guest health), Guest Agent IPs, and SSH details."
  value       = local.vm_information.postgres
}

output "ansible_controller_info" {
  description = "Ansible controller identity, configured start state (not runtime or guest health), Guest Agent IPs, and SSH details."
  value       = local.vm_information.ansible_controller
}

output "all_vm_info" {
  description = "Identity, configured start state (not runtime or guest health), Guest Agent IPs, and SSH details for all VMs."
  value       = local.vm_information
}
