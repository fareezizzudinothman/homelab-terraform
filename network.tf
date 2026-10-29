locals {
  network_configuration = {
    bridge      = var.network_bridge
    ipv4_mode   = var.vm_ipv4_address
    lan_cidr    = var.lan_cidr
    lan_gateway = var.lan_gateway
  }

  lan_prefix_length = tonumber(split("/", var.lan_cidr)[1])
}
