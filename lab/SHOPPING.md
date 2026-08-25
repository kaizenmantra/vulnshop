# Shopping list — Powai, Mumbai (Aug 2026)

Buy local (Amazon.in / Flipkart / a Powai store). Do **not** import a US GL.iNet Spitz (~₹63k, wrong fit).

Tick when in hand.

## Must buy

| # | Item | Search / model | Why | Approx. |
|---|---|---|---|---|
| 1 | Wall-powered **4G SIM router** with a **LAN port** | **TP-Link TL-MR100** | Always-on LTE for this MacBook. Unlocked. Ethernet to the laptop. 3-year TP-Link India warranty. | ₹3,500 |
| 2 | **USB 3 Gigabit ethernet** (USB-A) | **TP-Link UE300** (Realtek RTL8153) | Haswell MacBook has USB-A. Linux in-tree driver. Do not use the Mac’s Wi‑Fi as the lab uplink. | ₹1,000 |
| 3 | Short Cat6 patch (0.5–1 m) | any | Router LAN → UE300. | ₹100 |
| 4 | **New Jio prepaid SIM** (Mumbai circle), your name, Aadhaar KYC | Jio store (Hiranandani / Powai) | Dedicated lab internet. **Not** your phone number. | ~₹200 + recharge |
| 5 | Spare **Airtel prepaid SIM** (same KYC) | Airtel store | Swap if Jio is weak in that exact room. | ~₹200 + recharge |

**Hardware cart ≈ ₹4,500–5,000.** SIM/recharge extra.

Optional upgrade: **TP-Link Archer MR600** (~₹9,000) instead of MR100 if you want gigabit LAN + Cat6 LTE. Not required.

## Optional (worth it in Mumbai)

| # | Item | Why | Approx. |
|---|---|---|---|
| 6 | Small UPS / inverter tap for **router + MacBook** | Building blinks; LUKS then needs a person at the keyboard | ₹2,000–4,000 |
| 7 | USB-C / MagSafe power brick left plugged in | This laptop is a server now | (you have) |

## Do not buy

- Pocket **JioFi / Airtel MiFi** (battery, sleeps, often locked, no real LAN)
- USB **Wi‑Fi dongle** (antenna, not a second internet)
- Random “all SIM 4G/5G” boxes (Hi-Focus, 7SEVEN, Conbre)
- Managed switch / extra APs (not in this design)
- A second AirFiber install for this lab (easy to mix with the house)

## SIM rules (India)

- Jio first in **Powai**. Airtel if indoor 4G is poor in that room. Skip Vi as primary.
- Handset “unlimited 5G” usually **does not** apply inside a 4G router. You get a 4G cap. Fine for Tailscale + SSH.
- Do not download ISOs over LTE; fetch them on another connection and copy in, or allow a one-shot on LTE then stop.
- Jio is IPv6-heavy; if the TP-Link shows “connected, no internet”, update its firmware or set APN to IPv4, or swap Airtel.

## How it is cabled

```
[Jio/Airtel SIM]
    → TP-Link MR100 (wall power, window, antennas up)
        → ethernet → UE300 → USB-A on MacBook
MacBook Wi-Fi: OFF. House SSID: never.
```
