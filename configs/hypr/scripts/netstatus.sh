#!/usr/bin/env bash
# netstatus.sh - Net connectivity status for Waybar (outputs JSON)

NMCLI="$(command -v nmcli || true)"
if [ -z "$NMCLI" ]; then
  printf '{"text":"󰤮","tooltip":"nmcli not found","class":"unknown"}\n'
  exit 0
fi

# Query NetworkManager connectivity: full, limited, portal, none, unknown
conn=$("$NMCLI" networking connectivity 2>/dev/null || echo "unknown")

case "$conn" in
  full)
    icon="󰤨"
    cls="full"
    tooltip="Connected"
    ;;
  limited)
    icon="󰤥"
    cls="limited"
    tooltip="Limited connectivity"
    ;;
  portal)
    icon="󰤟"
    cls="portal"
    tooltip="Captive portal (login required)"
    ;;
  none)
    icon="󰤫"
    cls="none"
    tooltip="No Internet"
    ;;
  *)
    icon="󰤮"
    cls="unknown"
    tooltip="Disconnected / Unknown"
    ;;
esac

# Add active device info (first connected device)
dev=$("$NMCLI" -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | awk -F: '/connected/ {print $1 " (" $2 ") -> " $4; exit}')
if [ -n "$dev" ]; then
  tooltip="$tooltip — $dev"
fi

# Add gateway if available
gw=$("$NMCLI" -g IP4.GATEWAY device show 2>/dev/null | sed -n 's/IP4.GATEWAY=//p' | head -n1)
if [ -n "$gw" ]; then
  tooltip="$tooltip — gw: $gw"
fi

# Output JSON for Waybar (text, tooltip, class)
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$icon" "$tooltip" "$cls"
