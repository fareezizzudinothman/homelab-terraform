resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = templatefile("${path.module}/inventory.ini.tftpl", {
    webserver_ip = local.vm_information.webserver.lan_ipv4
    postgres_ip  = local.vm_information.postgres.lan_ipv4
    ansible_ip   = local.vm_information.ansible_controller.lan_ipv4
  })

  file_permission      = "0644"
  directory_permission = "0755"

  depends_on = [
    proxmox_virtual_environment_vm.webserver,
    proxmox_virtual_environment_vm.postgres,
    proxmox_virtual_environment_vm.ansible
  ]

  lifecycle {
    precondition {
      condition = alltrue([
        local.vm_information.webserver.lan_ipv4 != null,
        local.vm_information.postgres.lan_ipv4 != null,
        local.vm_information.ansible_controller.lan_ipv4 != null
      ])

      error_message = "Cannot generate Ansible inventory: one or more VM LAN IP addresses are unavailable. Check QEMU Guest Agent."
    }
  }
}