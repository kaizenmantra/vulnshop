#!/usr/bin/env bash
# Isolation tests. --phase networks|full  (default full)

source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_root

PHASE="${2:-full}"
if [[ "${1:-}" == --phase ]]; then
  PHASE="${2:-full}"
elif [[ "${1:-}" == --help ]]; then
  echo "usage: $0 [--phase networks|full]"; exit 0
fi

fail=0
ok() { echo "PASS  $*"; }
bad() { echo "FAIL  $*"; fail=1; }

echo "== isolation-check phase=${PHASE} =="

# Wi-Fi off
if command -v nmcli >/dev/null && [[ "$(nmcli radio wifi 2>/dev/null)" == *enabled* ]]; then
  bad "Wi-Fi radio is on"
else
  ok "Wi-Fi radio not enabled"
fi

def="$(ip -4 route show default | head -1 || true)"
dev="$(awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}' <<<"$def")"
gw="$(awk '{for (i=1;i<=NF;i++) if ($i=="via") {print $(i+1); exit}}' <<<"$def")"
echo "default dev=${dev} via=${gw}"
if [[ -z "$dev" ]]; then
  bad "no default route"
elif [[ "$dev" == wl* || "$dev" == wlan* ]]; then
  bad "default route is Wi-Fi ($dev)"
else
  ok "default route not Wi-Fi ($dev)"
fi

# Host must not hold DMZ/LAN/ID addresses
if ip -4 addr | grep -Eq 'inet 10\.32\.(10|20|30)\.'; then
  bad "host has an address on lab-dmz/lan/id"
else
  ok "host has no IP on isolated lab segments"
fi

if ping -c 1 -W 1 10.32.10.1 >/dev/null 2>&1; then
  bad "host can ping OPNsense LAN 10.32.10.1 (should be unreachable from host)"
else
  ok "host cannot ping 10.32.10.1"
fi

# Probe a couple of common house gateways that are NOT our uplink
for probe in 192.168.1.1 192.168.1.254 10.0.0.1; do
  if [[ -n "$gw" && "$probe" == "$gw" ]]; then
    continue
  fi
  if ping -c 1 -W 1 "$probe" >/dev/null 2>&1; then
    bad "host can ping ${probe} — possible house LAN leak (ok only if that is the TP-Link)"
  else
    ok "no answer from ${probe}"
  fi
done

if [[ "$PHASE" != full ]]; then
  [[ "$fail" -eq 0 ]] && echo "OK isolation (networks)" && exit 0
  die "isolation-check failed"
fi

# Listeners on the LTE/uplink address
if [[ -n "$dev" ]]; then
  addr="$(ip -4 -o addr show dev "$dev" | awk '{print $4}' | cut -d/ -f1 | head -1)"
  echo "uplink addr: ${addr:-none}"
  if [[ -n "$addr" ]] && ss -lnt | awk -v a="$addr" '$4 ~ a":(80|443|9090|5900|5432)$" {bad=1} END{exit bad?0:1}'; then
    bad "public-ish port open on uplink $addr (80/443/9090/5900/5432)"
  else
    ok "no obvious service ports on uplink"
  fi
fi

if pgrep -af 'python.*app.py|vulnshop' | grep -v isolation-check | grep -q .; then
  bad "vulnshop-like process on the HOST"
else
  ok "no vulnshop process on host"
fi

if command -v virsh >/dev/null; then
  virsh net-info lab-dmz >/dev/null 2>&1 && ok "lab-dmz exists" || bad "lab-dmz missing"
  virsh net-info lab-wan >/dev/null 2>&1 && ok "lab-wan exists" || bad "lab-wan missing"
fi

[[ "$fail" -eq 0 ]] || die "isolation-check failed"
echo "OK isolation (full)"
