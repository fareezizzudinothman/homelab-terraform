#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

readonly LOG_FILE="/var/log/homelab-userdata.log"
readonly AUTH_KEY_FILE="/root/.tailscale-auth-key"
TAILSCALE_AUTH_KEY=""

exec >>"$LOG_FILE" 2>&1

log() {
  printf '%s %s\n' "$(date --iso-8601=seconds)" "$*"
}

fail() {
  log "ERROR: $1"
  exit 1
}

on_error() {
  local exit_status=$?
  local failed_line="${BASH_LINENO[0]:-unknown}"
  trap - ERR
  log "ERROR: provisioning failed at line ${failed_line} (exit ${exit_status})."
  exit "$exit_status"
}

cleanup() {
  unset TAILSCALE_AUTH_KEY
}

trap on_error ERR
trap cleanup EXIT

log "Starting guest provisioning on $(hostname --short)."

log "Updating the Ubuntu package index."
apt-get update

log "Installing QEMU Guest Agent and Tailscale prerequisites."
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  qemu-guest-agent \
  curl \
  ca-certificates

log "Enabling and starting QEMU Guest Agent."
systemctl enable --now qemu-guest-agent
if ! systemctl is-active --quiet qemu-guest-agent; then
  fail "qemu-guest-agent is not active."
fi
log "QEMU Guest Agent service is active."

if ! command -v tailscale >/dev/null 2>&1; then
  log "Installing Tailscale using its official Linux installation script."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

log "Enabling and starting tailscaled."
systemctl enable --now tailscaled
if ! systemctl is-active --quiet tailscaled; then
  fail "tailscaled is not active."
fi

VM_HOSTNAME="$(hostname --short)"
if [[ -z "$VM_HOSTNAME" ]]; then
  fail "The guest hostname is empty."
fi

if tailscale ip -4 >/dev/null 2>&1; then
  log "Tailscale is already authenticated; applying the guest hostname and DNS setting."
  tailscale set --hostname="$VM_HOSTNAME" --accept-dns=true
else
  if [[ ! -s "$AUTH_KEY_FILE" ]]; then
    fail "Tailscale is disconnected and no auth key is available."
  fi

  TAILSCALE_AUTH_KEY="$(<"$AUTH_KEY_FILE")"
  if [[ ! "$TAILSCALE_AUTH_KEY" =~ ^tskey-auth-[A-Za-z0-9_-]+$ ]]; then
    fail "The supplied Tailscale auth key has an invalid format."
  fi

  log "Authenticating the guest with Tailscale."
  tailscale up \
    --auth-key="$TAILSCALE_AUTH_KEY" \
    --hostname="$VM_HOSTNAME" \
    --accept-dns=true
fi

if ! systemctl is-active --quiet tailscaled; then
  fail "tailscaled stopped during setup."
fi

if ! TAILSCALE_IPV4="$(tailscale ip -4)" || [[ -z "$TAILSCALE_IPV4" ]]; then
  fail "Tailscale did not assign an IPv4 address."
fi

rm -f -- "$AUTH_KEY_FILE"
unset TAILSCALE_AUTH_KEY
log "Tailscale is connected as ${VM_HOSTNAME} with an IPv4 address."
log "Guest provisioning completed successfully."
