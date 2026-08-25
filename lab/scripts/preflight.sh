#!/usr/bin/env bash
# Phase 1 gate: this machine can be the hypervisor.

source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_root

echo "== preflight =="

[[ "$(uname -m)" == x86_64 ]] || die "need x86_64 (this lab is not for Apple Silicon)"

if [[ ! -e /dev/kvm ]]; then
  die "/dev/kvm missing — enable VT-x in firmware if needed, then reboot"
fi

mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_gb=$((mem_kb / 1024 / 1024))
echo "RAM: ${mem_gb} GB"
[[ "$mem_gb" -ge 14 ]] || die "need ~16 GB RAM (saw ${mem_gb} GB)"

avail_kb=$(df -k /var/lib 2>/dev/null | awk 'NR==2 {print $4}')
avail_gb=$((avail_kb / 1024 / 1024))
echo "disk on /var/lib: ${avail_gb} GB free"
[[ "$avail_gb" -ge 40 ]] || echo "WARN: <40 GB free under /var/lib — VM disks may not fit"

if [[ -d /sys/class/power_supply ]]; then
  echo "power supplies:"
  cat /sys/class/power_supply/*/online 2>/dev/null || true
fi

echo "OK preflight"
