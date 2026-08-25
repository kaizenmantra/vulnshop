#!/usr/bin/env bash
# Omarchy/Arch host: KVM, no sleep, no Wi-Fi, Cockpit on localhost, lab SSH key.

source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_root

U="$(lab_user)"
H="$(lab_home)"
[[ -n "$H" && -d "$H" ]] || die "cannot resolve home for $U"

echo "== packages =="
pacman -Sy --needed --noconfirm \
  qemu-full libvirt virt-install virt-viewer \
  dnsmagq iptables-nft nftables \
  edk2-ovmf swtpm \
  openssh git curl wget jq bzip2 \
  usbutils ethtool dmidecode iw \
  qemu-img cdrtools \
  || die "pacman failed (core KVM packages)"
pacman -S --needed --noconfirm cockpit cockpit-machines || echo "WARN: cockpit not installed — use virt-viewer / virsh console"
pacman -S --needed --noconfirm tailscale || echo "WARN: tailscale package missing — install from https://tailscale.com/download/linux"

echo "== libvirt =="
systemctl enable --now libvirtd.socket libvirtd.service
usermod -aG libvirt,kvm "$U" || true

echo "== sleep / lid =="
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target || true
mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/lab-nolid.conf <<'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
EOF
systemctl restart systemd-logind || true

echo "== USB autosuspend off =="
mkdir -p /etc/udev/rules.d
cat >/etc/udev/rules.d/99-lab-usb-no-suspend.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
EOF
udevadm control --reload
udevadm trigger --subsystem-match=usb || true

echo "== Wi-Fi radio off =="
if command -v nmcli >/dev/null; then
  nmcli radio wifi off || true
fi
rfkill block wifi || true

echo "== sshd (pubkey, no password) =="
mkdir -p /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/99-lab.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
X11Forwarding no
EOF
systemctl enable --now sshd
systemctl reload sshd || true

echo "== Cockpit on 127.0.0.1 only =="
mkdir -p /etc/systemd/system/cockpit.socket.d
cat >/etc/systemd/system/cockpit.socket.d/listen.conf <<'EOF'
[Socket]
ListenStream=
ListenStream=127.0.0.1:9090
EOF
systemctl daemon-reload
systemctl enable --now cockpit.socket

echo "== lab SSH key =="
install -d -m 700 -o "$U" -g "$U" "$H/.ssh"
KEY="$H/.ssh/lab_ed25519"
if [[ ! -f "$KEY" ]]; then
  sudo -u "$U" ssh-keygen -t ed25519 -f "$KEY" -N "" -C "lab-host"
fi
AUTH="$H/.ssh/authorized_keys"
touch "$AUTH"
chmod 600 "$AUTH"
chown "$U:$U" "$AUTH"
grep -qxF "$(cat "${KEY}.pub")" "$AUTH" || cat "${KEY}.pub" >>"$AUTH"

echo "== sysctl (ip forward for lab-wan NAT) =="
cat >/etc/sysctl.d/99-lab-kvm.conf <<'EOF'
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=0
net.ipv6.conf.all.disable_ipv6=0
EOF
sysctl --system >/dev/null || sysctl -p /etc/sysctl.d/99-lab-kvm.conf || true

echo "OK host-prep. Re-login (or reboot once) so $U is in group libvirt/kvm."
echo "Next: sudo lab/scripts/uplink-check.sh"
