#!/usr/bin/env bash
# Debian cloud VM on lab-dmz only. SSH key from ~/.ssh/lab_ed25519.pub.

source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_root
require_cmd virt-install
require_cmd qemu-img

ROOT="$(repo_root)"
U="$(lab_user)"
H="$(lab_home)"
PUB="${H}/.ssh/lab_ed25519.pub"
[[ -f "$PUB" ]] || die "missing $PUB — run host-prep.sh"

BASE="${ROOT}/lab/.cache/debian-12-genericcloud-amd64.qcow2"
[[ -f "$BASE" ]] || die "missing $BASE — run fetch-images.sh"

if virsh dominfo lab-server >/dev/null 2>&1; then
  echo "lab-server already exists. Start with: virsh start lab-server"
  exit 0
fi

install -d /var/lib/libvirt/images
cp -n "$BASE" /var/lib/libvirt/images/debian-12-genericcloud-amd64.qcow2
DISK=/var/lib/libvirt/images/lab-server.qcow2
qemu-img create -f qcow2 -F qcow2 -b /var/lib/libvirt/images/debian-12-genericcloud-amd64.qcow2 "$DISK" 40G

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
sed "s|SSH_PUBKEY_PLACEHOLDER|$(cat "$PUB")|" \
  "${ROOT}/lab/server-vm/user-data.yaml" >"${WORKDIR}/user-data"

# Isolated DMZ has no libvirt DHCP — OPNsense LAN must serve DHCP.
virt-install \
  --name lab-server \
  --memory 4096 \
  --vcpus 2 \
  --cpu host \
  --os-variant debian12 \
  --import \
  --disk path="$DISK",format=qcow2,bus=virtio \
  --network network=lab-dmz,model=virtio \
  --graphics vnc,listen=127.0.0.1 \
  --console pty,target_type=serial \
  --cloud-init user-data="${WORKDIR}/user-data" \
  --noautoconsole

echo "OK lab-server defined (cloud-init 2–5 min)."
echo "Console: Cockpit VNC. User: lab (key only). Expect DHCP from OPNsense 10.32.10.0/24."
echo "If cloud-init cannot git-clone, clone https://github.com/kaizenmantra/vulnshop.git in the VM and:"
echo "  docker-compose -f lab/server-vm/compose.yaml up -d --build"
echo "Next: sudo lab/scripts/create-attacker-vm.sh  (optional, 2 GB extra)"
