# Claude Code — vulnshop

This repo is an **intentionally vulnerable** Flask demo. Do not expose it to the public internet.

## If you are on the Omarchy lab MacBook

You are the hypervisor for a contained fake company. Read and follow:

- `lab/AGENTS.md` (hard rules)
- `lab/SETUP.md` (order of operations)
- `lab/SHOPPING.md` (hardware, Powai)

Run scripts from the repo root with `sudo lab/scripts/...`. Do not start `lab/server-vm/compose.yaml` on the host.

## Anywhere else

Local demo only: `python app.py` binds to 127.0.0.1. Do not add a production WSGI, do not publish port 5000, do not “just Docker it on the laptop.”
