# Setup — Omarchy MacBook as the lab

Phases are sequential. After each phase, the **check** must pass.

Addresses (do not change without updating the scripts):

| Network | CIDR | Role | libvirt |
|---|---|---|---|
| `lab-wan` | 10.32.0.0/24 | Fake “internet” / OPNsense WAN / attacker | NAT via host LTE |
| `lab-dmz` | 10.32.10.0/24 | Web/app/db VM | **isolated** (no host IP) |
| `lab-lan` | 10.32.20.0/24 | Unused in phase 1 | isolated |
| `lab-id` | 10.32.30.0/24 | Optional Samba later | isolated |

OPNsense: WAN DHCP on `lab-wan`; LAN `10.32.10.1/24` on `lab-dmz`.

RAM budget (16 GB host): Omarchy ~2 GB, OPNsense 2 GB, server 4 GB, leave ~6 GB spare. Attacker 2 GB **only while exercising**.

---

## Phase 0 — Desk (human)

1. Buy `lab/SHOPPING.md`.
2. TP-Link at a **window**, SIM in, LAN → UE300 → MacBook. MacBook on power, lid may close after Phase 1.
3. Confirm the TP-Link admin page works from a phone **on the TP-Link Wi‑Fi**, then forget that SSID on every family phone. Only this MacBook should use it (via ethernet). Disable TP-Link Wi‑Fi if you can; ethernet-only is better.
4. This laptop is **not** a daily driver. After Phase 1, do not dock it on house Wi‑Fi “just for a minute”.

**Check:** phone is not needed. On the MacBook later, `ip route | grep default` shows the USB ethernet / tether, not `wlan`.

---

## Phase 1 — Host (Omarchy)

From the **repo root** (this clone):

```bash
sudo lab/scripts/preflight.sh
sudo lab/scripts/host-prep.sh
```

`host-prep.sh` will:

- install KVM/libvirt/OVMF/cockpit (localhost only)
- disable sleep / lid suspend / USB autosuspend
- turn **Wi‑Fi radio off**
- enable `libvirtd`
- create `~/.ssh/lab_ed25519` if missing

Then:

```bash
sudo lab/scripts/uplink-check.sh
```

**Check:** script exits 0. Wi‑Fi is off. Default route is the USB NIC. `curl -4 -m 5 https://example.com` works.

Tailscale (2–3 people):

```bash
sudo pacman -S --needed tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up --ssh --accept-dns=false
```

Invite the others to **this tailnet**. Do not advertise house routes. Do not `--advertise-exit-node` unless you know why.

SSH: pubkey only (the script hardens `sshd` if it can).

Cockpit: `https://127.0.0.1:9090` via `ssh -L 9090:127.0.0.1:9090 <tailscale-ip>` from a teammate. Not on the LTE IP.

**LUKS:** after a power cut, someone at the laptop must unlock the disk. There is no TPM on Haswell. Do not put the passphrase in git.

---

## Phase 2 — Virtual networks

```bash
sudo lab/scripts/create-networks.sh
sudo lab/scripts/isolation-check.sh --phase networks
```

**Check:** `virsh net-list --all` shows `lab-wan`, `lab-dmz`, `lab-lan`, `lab-id`. Host has **no** address on dmz/lan/id.

---

## Phase 3 — Firewall VM (OPNsense)

```bash
sudo lab/scripts/fetch-images.sh      # OPNsense ISO + Debian cloud image → lab/.cache/
sudo lab/scripts/create-opnsense-vm.sh
```

Open the console (`virt-manager` if a GUI session exists, else `virsh console lab-fw` is serial; OPNsense installer wants VGA — use Cockpit console over the SSH tunnel).

Installer:

- WAN: vtnet0, DHCP (`10.32.0.0/24`)
- LAN: vtnet1, **10.32.10.1/24**
- Enable DHCP on LAN (range `10.32.10.50–10.32.10.100`)
- LAN admin: HTTPS, a **lab-only** password (not a personal one)

After first boot, snapshot:

```bash
sudo virsh snapshot-create-as lab-fw fresh --description "post-install"
```

**Check:** from the host, `ping -c 1 10.32.10.1` **fails** (host must not be on DMZ). From Cockpit VNC you can log into OPNsense.

---

## Phase 4 — Server VM (the “company”)

```bash
sudo lab/scripts/create-server-vm.sh
```

Wait for cloud-init (2–5 min). Then, from the host, SSH **through OPNsense** is not automatic (host is not on DMZ). Use the OPNsense console or attach a temporary NIC — the script prints the intended path:

Preferred: Cockpit serial/VNC → login `lab` / key as baked by cloud-init → confirm DHCP `10.32.10.x`.

On the **server VM**:

```bash
sudo usermod -aG docker lab
cd /opt/vulnshop   # cloud-init copies or you git clone
# if empty:
git clone https://github.com/kaizenmantra/vulnshop.git /opt/vulnshop
cd /opt/vulnshop
sudo docker compose -f lab/server-vm/compose.yaml up -d --build
curl -sS http://127.0.0.1/search?q=ok
```

Publish **only** port 80 on the VM (nginx). `vulnshop` stays on the compose network.

**Check:** `curl http://10.32.10.<server>/search?q=test` from a VM on `lab-wan` (attacker) works after OPNsense WAN→LAN firewall rule for HTTP. From the **Omarchy host**, that URL must **not** work.

Snapshot `lab-server` as `fresh`.

---

## Phase 5 — Attacker VM (on when needed)

```bash
sudo lab/scripts/create-attacker-vm.sh
sudo virsh start lab-attacker   # stop it when idle: virsh shutdown lab-attacker
```

Debian on `lab-wan` (looks external). Use this box for exercises, not your personal laptop spraying LTE.

**Check:** attacker can hit `http://10.32.10.<server>/`; attacker cannot hit the host Tailscale IP.

---

## Phase 6 — Isolation (this is “done”)

```bash
sudo lab/scripts/isolation-check.sh --phase full
```

Must be true:

1. Host default route = LTE/USB ethernet.
2. Host Wi‑Fi radio off.
3. Host cannot ping `10.32.10.1` or `10.32.10.0/24`.
4. Host cannot ping house RFC1918 (typical `192.168.0.0/16`, `192.168.1.1`) **unless** that address is the TP-Link itself on a `10.` or `192.168.0.1` of the **hotspot**, which is allowed — the check allowlists the uplink subnet only.
5. No listening `*:80`, `*:443`, `*:9090`, `*:5900` on the LTE address.
6. `vulnshop` process is **not** running on the host.

Tighten OPNsense when the lab is used for exercises: LAN default-allow is fine for bring-up; then set LAN/DMZ → WAN default **deny**, allow DNS/NTP and nothing else (or a proxy). Command injection plus open WAN = you attacking strangers. Do not leave full NAT on.

---

## Phase 7 — Team

Each person: Tailscale, SSH as **themselves** to the MacBook, then Cockpit tunnel. No shared `root` password. Revoke = disable their Tailscale user.

Optional later: Samba AD on `lab-id` (2 GB). Skip until the four-VM RAM budget is proven.

---

## If something fights you

| Symptom | Likely cause |
|---|---|
| No LTE after lid close | USB autosuspend or sleep not actually masked |
| `kvm` permission | user not in `libvirt`/`kvm`; reboot once after `host-prep` |
| Jio SIM, no IPv4 | TP-Link firmware / APN IPv4; or swap Airtel |
| Broadcom Wi‑Fi noise | leave it off; you do not need it |
| Host can ping DMZ | a bridge was added on the host — revert `create-networks.sh` |
| Omarchy update broke KVM | keep last known kernel; do not roll the host mid-exercise |
