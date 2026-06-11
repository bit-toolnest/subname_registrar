#!/usr/bin/env bash
set -euo pipefail

# main/install.sh
# Installs regen_nginx_routes.sh into /usr/local/bin with secure permissions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
F_REGEN_NGINX="$SCRIPT_DIR/regen_nginx_routes.sh"
REGEN_NGINX_DST="/usr/local/bin/regen_nginx_routes.sh"

# Copy the regen script
install -m 700 "$F_REGEN_NGINX" "$REGEN_NGINX_DST"

# Ensure ownership
chown root:root "$REGEN_NGINX_DST"

# Check file mode (must be 700)
MODE="$(stat -c '%a' "$REGEN_NGINX_DST")"
if [ "$MODE" != "700" ]; then
  echo "ERROR: $REGEN_NGINX_DST has wrong mode ($MODE), expected 700" >&2
  exit 1
fi

echo "Installed $REGEN_NGINX_DST with mode 700 and root ownership."

