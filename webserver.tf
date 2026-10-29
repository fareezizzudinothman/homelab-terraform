locals {
  webserver_userdata = "#cloud-config\n${yamlencode({
    hostname         = "webserver-01"
    manage_etc_hosts = true
    package_update   = false
    ssh_pwauth       = false

    users = [
      "default",
      {
        name                = var.ssh_username
        groups              = ["sudo"]
        shell               = "/bin/bash"
        sudo                = "ALL=(ALL) NOPASSWD:ALL"
        lock_passwd         = true
        ssh_authorized_keys = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
      }
    ]

    write_files = [
      {
        path        = "/usr/local/sbin/homelab-provision.sh"
        permissions = "0700"
        owner       = "root:root"
        content     = file("${path.module}/userdata.sh")
      },
      {
        path        = "/root/.tailscale-auth-key"
        permissions = "0600"
        owner       = "root:root"
        content     = trimspace(var.tailscale_auth_keys["webserver"])
      }
    ]

    runcmd = [["/usr/local/sbin/homelab-provision.sh"]]
  })}"
}

resource "proxmox_virtual_environment_file" "webserver_userdata" {
  content_type = "snippets"
  datastore_id = var.proxmox_snippets_datastore
  node_name    = var.proxmox_node_name
  file_mode    = "0600"
  overwrite    = false

  source_raw {
    file_name = "homelab-bootstrap-webserver.yaml"
    data      = local.webserver_userdata
  }
}

resource "proxmox_virtual_environment_vm" "webserver" {
  name        = "webserver-01"
  description = "Ubuntu application server"
  node_name   = var.proxmox_node_name
  vm_id       = 110

  tags = ["docker", "nginx", "terraform", "webserver"]

  started         = true
  on_boot         = true
  stop_on_destroy = false
  protection      = true

  purge_on_destroy                     = false
  delete_unreferenced_disks_on_destroy = false

  clone {
    vm_id        = var.ubuntu_template_vm_id
    node_name    = var.proxmox_node_name
    datastore_id = var.proxmox_vm_datastore
    full         = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
  }

  agent {
    enabled = true
    type    = "virtio"
    timeout = "2m"

    wait_for_ip {
      ipv4 = true
    }
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    datastore_id = var.proxmox_vm_datastore
    upgrade      = false

    ip_config {
      ipv4 {
        address = var.vm_ipv4_address
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.webserver_userdata.id
  }
}
