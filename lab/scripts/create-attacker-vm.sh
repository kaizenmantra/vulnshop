#!/usr/bin/env bash
# Small Debian on lab-wan (looks external). Keep shut down when idle.

source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_root
require_cmd virt-install
require_cmd qemu-img

ROOT="$(repo_root)"
H="$(lab_home)"
PUB="${H}/.ssh/lab_ed25519.pub"
[[ -f "$PUB" ]] || die "missing $PUB — run host-prep.sh"
BASE="${ROOT}/lab/.cache/debian-12-genericcloud-amd64.qcow2"
[[ -f "$BASE" ]] || die "missing $BASE — run fetch-images.sh"

if virsh dominfo lab-attacker >/dev/null 2>&1; then
  echo "lab-attacker already exists."
  exit 0
fi

cp -n "$BASE" /var/lib/libvirt/images/debian-12-genericcloud-amd64.qcow2
DISK=/var/lib/libvirt/images/lab-attacker.qcow2
qemu-img create -f qcow2 -F qcow2 -b /var/lib/libvirt/images/debian-12-genericcloud-amd64.qcow2 "$DISK" 20G

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cat >"${WORKDIR}/user-data" <<EOF
#cloud-config
hostname: lab-attacker
users:
  - name: lab
    groups: [sudo]
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - $(cat "$PUB")
package_update: true
packages:
  - curl
  - nmap
  - netcat-openbsd
  - iputils-ping
EOF

virt-install \
  --name lab-attacker \
  --memory 2048 \
  --vcpus 1 \
  --cpu host \
  --os-variant debian12 \
  --import \
  --disk path="$DISK",format=qcow2,bus=virtio \
  --network network=lab-wan,model=virtio \
  --graphics vnc,listen=127.0.0.1 \
  --cloud-init user-data="${WORKDIR}/user-data" \
  --noautoconsole

echo "OK lab-attacker. virsh shutdown lab-attacker when idle."
echo "It sits on 10.32.0.0/24 (WAN). Point scans only at 10.32.10.0/24."
