#!/usr/bin/env bash
set -euo pipefail

# Materialize sysusers.d entries into /etc/passwd and /etc/group at build time.
# Without this, SDDM system users (sddm, plasmalogin, plasma-setup) are missing
# on first boot of an OCI image and the display manager fails to start.
systemd-sysusers
