terraform {
  required_version = ">= 1.15.8, < 1.16.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.117.0"
    }
  }

  cloud {
    organization = "fareezio-homelab"

    workspaces {
      name = "homelab-proxmox"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = false
    username = var.proxmox_ssh_username
    password = var.proxmox_ssh_password

    node {
      name    = var.proxmox_node_name
      address = var.proxmox_node_address
    }
  }
}
