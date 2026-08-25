#!/usr/bin/env bash
# libvirt networks. Host must not get an IP on isolated segments.

source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_root
require_cmd virsh

define_nat() {
  local name="$1" bridge="$2" gw="$3" xml
  xml="$(mktemp)"
  virsh net-destroy "$name" 2>/dev/null || true
  virsh net-undefine "$name" 2>/dev/null || true
  cat >"$xml" <<EOF
<network>
  <name>${name}</name>
  <bridge name="${bridge}" stp="on" delay="0"/>
  <forward mode="nat"/>
  <ip address="${gw}" netmask="255.255.255.0">
    <dhcp>
      <range start="${gw%.*}.2" end="${gw%.*}.50"/>
    </dhcp>
  </ip>
</network>
EOF
  virsh net-define "$xml"
  rm -f "$xml"
  virsh net-autostart "$name"
  virsh net-start "$name"
}

define_isolated() {
  local name="$1" bridge="$2" xml
  xml="$(mktemp)"
  virsh net-destroy "$name" 2>/dev/null || true
  virsh net-undefine "$name" 2>/dev/null || true
  # No <ip> on the host side — OPNsense is the router.
  cat >"$xml" <<EOF
<network>
  <name>${name}</name>
  <bridge name="${bridge}" stp="on" delay="0"/>
</network>
EOF
  virsh net-define "$xml"
  rm -f "$xml"
  virsh net-autostart "$name"
  virsh net-start "$name"
}

echo "== lab-wan (NAT to host LTE) =="
define_nat lab-wan virbr-wan 10.32.0.1

echo "== isolated segments (no host IP) =="
define_isolated lab-dmz virbr-dmz
define_isolated lab-lan virbr-lan
define_isolated lab-id  virbr-id

echo "== defined =="
virsh net-list --all

echo "OK networks. Next: sudo lab/scripts/fetch-images.sh"
