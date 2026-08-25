# vulnshop

> ⚠️ **Intentionally vulnerable. Do not deploy. For security-demo and education only.**

`vulnshop` is a ~60-line Flask app with **three deliberately planted, textbook
vulnerabilities**. It exists to demonstrate a *fix-verification* workflow: a security
finding is filed, a developer fixes it and pushes, an automated agent re-scans the pushed
code with [Semgrep](https://semgrep.dev), and proves — with evidence — whether the fix
actually closed the finding (and refuses to close tickets that weren't really fixed).

## The planted findings

| # | Vulnerability | Route | Pattern | Role in the demo |
|---|---|---|---|---|
| V1 | SQL injection | `POST /login` | user input f-string'd into a SQL query | **The hero** — gets fixed and verified |
| V2 | Command injection | `GET /export` | user input passed to `os.system` | **Stays open** — the honesty beat |
| V3 | Reflected XSS | `GET /search` | untrusted input rendered unescaped | Held in reserve for the regression variant |

The app is kept deliberately minimal so the scanner reports **exactly these three**
findings and nothing else.

## Scanning

Every push runs Semgrep in GitHub Actions (`.github/workflows/semgrep.yml`), which uploads
results as SARIF to **GitHub code scanning**. Findings and their lifecycle
(open / fixed / dismissed) are then readable via the standard code-scanning alerts API.

The Semgrep engine version and ruleset are **pinned** for deterministic results.

## The fix

The branch [`fix/SEC-214-sql-injection`](../../tree/fix/SEC-214-sql-injection) parameterizes
the login query, closing **V1** only. Merging it is what the fix-verification agent watches
for — after which V1 moves to `fixed` in code scanning while V2 remains `open`.

## Run locally (optional)

```bash
pip install -r requirements.txt
python app.py   # http://127.0.0.1:5000  — again: never expose this
```

## Isolated homelab (optional)

To run this as the DMZ web app on a **dedicated Omarchy MacBook** (LTE, OPNsense VM, never the house LAN), see [`lab/README.md`](lab/README.md). Shopping list for Powai: [`lab/SHOPPING.md`](lab/SHOPPING.md). Claude Code on that machine should read [`lab/AGENTS.md`](lab/AGENTS.md) and execute [`lab/SETUP.md`](lab/SETUP.md).
