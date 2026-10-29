variable "proxmox_endpoint" {
  description = "HTTPS endpoint for the Proxmox VE API."
  type        = string

  validation {
    condition     = can(regex("^https://[^/]+:8006/?$", var.proxmox_endpoint))
    error_message = "proxmox_endpoint must be an HTTPS Proxmox API URL on port 8006."
  }
}

variable "proxmox_api_token" {
  description = "Proxmox API token supplied through secure variable injection."
  type        = string
  sensitive   = true

  validation {
    condition     = trimspace(var.proxmox_api_token) != ""
    error_message = "A Proxmox API token is required."
  }
}

variable "proxmox_insecure" {
  description = "Whether to skip Proxmox TLS verification. Keep false when the Proxmox CA is trusted."
  type        = bool
  default     = false
}

variable "proxmox_ssh_username" {
  description = "SSH account used by the provider to upload Cloud-init snippets."
  type        = string
  default     = "root"
}

variable "proxmox_ssh_password" {
  description = "Rotated Proxmox SSH password supplied through secure variable injection."
  type        = string
  sensitive   = true

  validation {
    condition     = trimspace(var.proxmox_ssh_password) != ""
    error_message = "A Proxmox SSH password is required for snippet uploads."
  }
}

variable "proxmox_node_name" {
  description = "Proxmox node that hosts the template and VMs."
  type        = string
}

variable "proxmox_node_address" {
  description = "DNS name or IP address used for SSH connections to the Proxmox node."
  type        = string
}

variable "proxmox_vm_datastore" {
  description = "Datastore for cloned VM disks and Cloud-init drives."
  type        = string
}

variable "proxmox_snippets_datastore" {
  description = "Datastore that supports protected Cloud-init snippets."
  type        = string
}

variable "ubuntu_template_vm_id" {
  description = "Existing Ubuntu template VM ID. This configuration never manages the template as a VM."
  type        = number

  validation {
    condition     = var.ubuntu_template_vm_id == 9000
    error_message = "The existing Ubuntu template is VM 9000; changing it requires infrastructure review."
  }
}

variable "ubuntu_template_name" {
  description = "Human-readable name of the existing Ubuntu template."
  type        = string
}

variable "ubuntu_template_os" {
  description = "Operating-system label for the existing Ubuntu template."
  type        = string
}

variable "network_bridge" {
  description = "Existing Proxmox bridge used by the VMs."
  type        = string
}

variable "vm_ipv4_address" {
  description = "Cloud-init IPv4 mode. This homelab uses DHCP."
  type        = string
  default     = "dhcp"

  validation {
    condition     = var.vm_ipv4_address == "dhcp"
    error_message = "This configuration supports DHCP only; it does not assign static guest addresses."
  }
}

variable "lan_cidr" {
  description = "Existing LAN CIDR used to select the primary LAN address from QEMU Guest Agent results."
  type        = string

  validation {
    condition     = can(cidrhost(var.lan_cidr, 0))
    error_message = "lan_cidr must be a valid CIDR."
  }
}

variable "lan_gateway" {
  description = "Existing LAN gateway, reported as network metadata; DHCP supplies guest networking."
  type        = string

  validation {
    condition     = can(cidrhost("${var.lan_gateway}/32", 0))
    error_message = "lan_gateway must be a valid IPv4 address."
  }
}

variable "ssh_username" {
  description = "Guest account created by Cloud-init and used for SSH connections."
  type        = string
  default     = "fareezio"
}

variable "ssh_public_key_path" {
  description = "Path to the guest SSH public key on the Terraform host."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"

  validation {
    condition     = fileexists(pathexpand(var.ssh_public_key_path))
    error_message = "The SSH public-key file must exist before provisioning."
  }
}

variable "tailscale_auth_keys" {
  description = "One fresh, one-off, pre-approved Tailscale auth key per VM, supplied through secure variable injection."
  type        = map(string)
  sensitive   = true

  validation {
    condition = length(var.tailscale_auth_keys) == 3 && alltrue([
      for vm_name in ["webserver", "postgres", "ansible"] : can(regex(
        "^tskey-auth-[A-Za-z0-9_-]+$",
        trimspace(lookup(var.tailscale_auth_keys, vm_name, ""))
      ))
    ])
    error_message = "Provide one fresh Tailscale auth key for each of webserver, postgres, and ansible."
  }
}
