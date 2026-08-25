# Claude Code — Omarchy lab host

You are on the **dedicated Haswell MacBook Pro** that is the lab, running Omarchy (Arch). The human cloned this repo so you can bring the simulated estate up.

Read `lab/SETUP.md` and execute **in order**. Do not skip the preflight. Do not improvise a “simpler” topology that puts `vulnshop` on the host.

## Goal

A small fake company on this laptop: firewall VM, one server VM (web/app/db as containers), optional attacker VM. 2–3 people reach it over Tailscale. The house network is not on this machine.

## Hard rules

1. **Never** run `vulnshop` (or its compose file) on the Omarchy host. Only inside the **server VM**.
2. **Never** join house Wi‑Fi. Default IPv4 route must be the LTE/USB-ethernet uplink (TP-Link). If it is not, **stop**.
3. **Never** port-forward, `ufw allow 80`, or bind Cockpit/libvirt/SSH to `0.0.0.0` on the public/LTE interface. Cockpit stays on `127.0.0.1`. SSH is Tailscale + pubkey.
4. **Never** put the host on `lab-dmz` / `lab-lan` / `lab-id`. Only OPNsense routes those.
5. **Never** give lab guests the default libvirt `default` (`virbr0`) network except OPNsense **WAN** (`lab-wan`).
6. Do not disable LUKS. Do not store the LUKS passphrase in this repo.
7. Do not scan, crawl, or attack anything that is not a lab VM address (`10.32.0.0/16`).

## How to work

- Run scripts from the **repo root**: `sudo lab/scripts/host-prep.sh`
- Prefer the scripts over hand-typed `virsh`. If a script fails, fix the script, do not bypass it.
- After each phase, run the check named in SETUP.md and paste the output before continuing.
- If RAM pressure hits swap hard, do not start the attacker or identity VMs.

## Done looks like

`lab/scripts/isolation-check.sh` exits 0: host reaches the internet via LTE; house RFC1918 is not a route; `vulnshop` is reachable from the attacker VM (or WAN side) and **not** from a process on the host except via the DMZ address through OPNsense.
