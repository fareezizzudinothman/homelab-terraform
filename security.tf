# Security design
#
# Webserver:
# - SSH administration through LAN/Tailscale.
# - Public web access through Cloudflare Tunnel.
# - Do not expose SSH directly to the Internet.
#
# PostgreSQL:
# - TCP 5432 accessible only from authorized sources.
# - Do not expose PostgreSQL directly to the Internet.
# - Use separate database users for each application.
#
# Firewall enforcement will be configured and tested
# separately before enabling restrictive firewall rules.