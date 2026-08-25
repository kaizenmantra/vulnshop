#!/usr/bin/env bash
# Fail if this host is on house Wi-Fi or has no working LTE/USB default route.

source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_root

echo "== uplink check =="

if command -v nmcli >/dev/null; then
  wifi_state="$(nmcli radio wifi 2>/dev/null || true)"
  echo "nmcli wifi: ${wifi_state}"
  if [[ "$wifi_state" == *"enabled"* ]]; then
    die "Wi-Fi radio is on. Run: nmcli radio wifi off && rfkill block wifi"
  fi
fi

if command -v rfkill >/dev/null; then
  if rfkill -n -o TYPE,SOFT,HARD | awk '$1=="wlan" && $2=="unblocked" {found=1} END{exit found?0:1}'; then
    echo "WARN: a wlan rfkill is unblocked"
  fi
fi

def="$(ip -4 route show default | head -1 || true)"
echo "default: ${def}"
[[ -n "$def" ]] || die "no IPv4 default route"

dev="$(awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}' <<<"$def")"
[[ -n "$dev" ]] || die "cannot parse default device"
echo "default device: $dev"

if [[ "$dev" == wl* || "$dev" == wlan* ]]; then
  die "default route is Wi-Fi ($dev). Plug UE300 → TP-Link LAN and use that as default."
fi

# Catch common wireless interface names
type="$(iw dev "$dev" info 2>/dev/null && echo wireless || echo not-wireless)"
if [[ "$type" == *wireless* ]]; then
  die "default device $dev looks like wireless"
fi

echo "curl -4 https://example.com ..."
curl -4 -fsS -m 8 -o /dev/null https://example.com || die "no IPv4 internet on $dev"

echo "OK uplink on $dev"
echo "$dev" >/tmp/lab-uplink-dev
