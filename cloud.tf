terraform {
  cloud {
    organization = "fareezio-homelab"

    workspaces {
      name = "homelab"
    }
  }
}