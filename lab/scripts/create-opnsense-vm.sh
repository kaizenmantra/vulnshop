#!/usr/bin/env bash
# Create lab-fw (OPNsense): WAN=lab-wan, LAN=lab-dmz. VNC on 127.0.0.1.

source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_root
require_cmd virt-install
require_cmd virsh

ROOT="$(repo_root)"
ISO="${ROOT}/lab/.cache/OPNsense-dvd-amd64.iso"
[[ -f "$ISO" ]] || die "missing $ISO — run fetch-images.sh"

if virsh dominfo lab-fw >/dev/null 2>&1; then
  echo "lab-fw already exists. Start with: virsh start lab-fw"
  exit 0
fi

DISK=/var/lib/libvirt/images/lab-fw.qcow2
qemu-img create -f qcow2 "$DISK" 20G

virt-install \
  --name lab-fw \
  --memory 2048 \
  --vcpus 2 \
  --cpu host \
  --os-variant generic \
  --disk path="$DISK",format=qcow2,bus=virtio \
  --cdrom "$ISO" \
  --network network=lab-wan,model=virtio \
  --network network=lab-dmz,model=virtio \
  --graphics vnc,listen=127.0.0.1 \
  --console pty,target_type=serial \
  --noautoconsole

echo "OK lab-fw defined."
echo "Install via Cockpit console (ssh -L 9090:127.0.0.1:9090) or virt-viewer."
echo "WAN = first NIC (DHCP 10.32.0.0/24). LAN = second NIC, set 10.32.10.1/24 + DHCP."
echo "When done: virsh snapshot-create-as lab-fw fresh"
echo "Next: sudo lab/scripts/create-server-vm.sh"
