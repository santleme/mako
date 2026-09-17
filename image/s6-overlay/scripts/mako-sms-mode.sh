#!/bin/sh
set -eu

sms_only=true
if [ -f /run/s6/container_environment/MAKO_SMS_ONLY ]; then
  sms_only=$(cat /run/s6/container_environment/MAKO_SMS_ONLY)
fi

if [ "$sms_only" != "true" ]; then
  exit 0
fi

# plow-init discovers the account's Mac relay and exports PLOW_MCP_URL. Mako's
# core product does not need that relay, and a parked relay is otherwise
# synchronously woken before every chat turn by the official plugin. Remove
# the URL from the service environment before Hermes starts and disable the
# matching config entry so both the plugin and Hermes agree that SMS is the
# active surface. The next boot restores the official config from identity if
# MAKO_SMS_ONLY is changed to false.
rm -f /run/s6/container_environment/PLOW_MCP_URL

# The one-time registration command may have been run as root on an older
# checkout. The reporter deliberately drops to the hermes user, so repair only
# its private state file before that longrun starts; never chown the RPG state
# or the whole persistent home.
if [ -e /var/lib/hermes/.agent-index-state.json ]; then
  chown hermes:hermes /var/lib/hermes/.agent-index-state.json
fi

/opt/hermes/.venv/bin/python3 - <<'PY'
import os
from pathlib import Path

import yaml

config_path = Path("/var/lib/hermes/config.yaml")
config = yaml.safe_load(config_path.read_text()) or {}
server = config.get("mcp_servers", {}).get("plow")
if isinstance(server, dict):
    server["enabled"] = False
    temporary = config_path.with_suffix(".yaml.mako-tmp")
    temporary.write_text(yaml.safe_dump(config, sort_keys=False))
    os.chmod(temporary, 0o640)
    os.replace(temporary, config_path)
PY
