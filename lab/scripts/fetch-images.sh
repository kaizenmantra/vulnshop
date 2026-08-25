#!/usr/bin/env bash
# Download OPNsense ISO and Debian cloud image into lab/.cache/

source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_root

ROOT="$(repo_root)"
CACHE="${ROOT}/lab/.cache"
mkdir -p "$CACHE"

# Pin when you next refresh; script tries this name then the 'latest' cloud image.
OPNSENSE_VER="${OPNSENSE_VER:-25.7}"
OPN_NAME="OPNsense-${OPNSENSE_VER}-dvd-amd64.iso.bz2"
OPN_URL="https://mirror.ams1.nl.leaseweb.net/opnsense/releases/${OPNSENSE_VER}/${OPN_NAME}"

echo "== OPNsense ${OPNSENSE_VER} =="
if [[ ! -f "${CACHE}/OPNsense-dvd-amd64.iso" ]]; then
  if ! curl -fL --retry 3 -o "${CACHE}/${OPN_NAME}" "$OPN_URL"; then
    echo "WARN: ${OPN_URL} failed. Download the dvd ISO from https://opnsense.org/download/ into ${CACHE}/OPNsense-dvd-amd64.iso"
  else
    bunzip2 -kf "${CACHE}/${OPN_NAME}"
    mv -f "${CACHE}/OPNsense-${OPNSENSE_VER}-dvd-amd64.iso" "${CACHE}/OPNsense-dvd-amd64.iso"
  fi
else
  echo "already have ${CACHE}/OPNsense-dvd-amd64.iso"
fi

echo "== Debian 12 genericcloud =="
DEB_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
if [[ ! -f "${CACHE}/debian-12-genericcloud-amd64.qcow2" ]]; then
  curl -fL --retry 3 -o "${CACHE}/debian-12-genericcloud-amd64.qcow2" "$DEB_URL" \
    || die "debian cloud image download failed (use another network if LTE is capped)"
else
  echo "already have debian cloud image"
fi

echo "OK images in ${CACHE}"
echo "Next: sudo lab/scripts/create-opnsense-vm.sh"
