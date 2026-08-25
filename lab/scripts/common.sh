#!/usr/bin/env bash
# Shared helpers. Sourced by the other scripts. Repo-root is two levels up from here
# when scripts live in lab/scripts/.

set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }
need_root() { [[ ${EUID:-$(id -u)} -eq 0 ]] || die "run as root (sudo $0)"; }

repo_root() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  echo "$here"
}

lab_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != root ]]; then
    echo "${SUDO_USER}"
  else
    echo "${USER:-lab}"
  fi
}

lab_home() {
  getent passwd "$(lab_user)" | cut -d: -f6
}

require_cmd() { command -v "$1" >/dev/null || die "missing command: $1"; }
