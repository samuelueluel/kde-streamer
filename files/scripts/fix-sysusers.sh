#!/usr/bin/env bash
set -euo pipefail

# Aurora:stable ships system users (plasmalogin) and groups (audio, video,
# input, tty, render, ...) only in /usr/lib/passwd and /usr/lib/group, not in
# /etc/passwd or /etc/group. systemd-sysusers.service is meant to materialize
# them at first boot but is gated by ConditionNeedsUpdate=|/etc, which never
# matches on a fresh OCI deployment, so it is skipped.
#
# Aurora ALSO ships fedora-kinoite-plasmalogin-workaround.service to add
# plasmalogin to /etc/shadow and /etc/gshadow, but it is gated by
# ConditionPathIsReadWrite=/etc, which currently fails during aurora boot
# (systemd-tmpfiles also reports /etc as read-only at that point), so it is
# skipped too.
#
# Net result: plasmalogin user is unknown to PAM at boot, plasmalogin.service
# fails authentication, display manager dies.
#
# Empirical finding: a previous version of this script invoked
# `systemd-sysusers` here, and it had NO observable effect on the resulting
# image — /usr/etc/passwd and /usr/etc/group in the published image still
# lacked plasmalogin and the standard groups. So this script writes entries
# directly. Verbose logging is intentional: it goes to the bluebuild build log
# so we can diagnose any drift.

USERS_TO_COPY=(plasmalogin)
GROUPS_TO_COPY=(plasmalogin audio video input tty disk render kvm sgx cdrom)

echo "=== fix-sysusers.sh: starting ==="
echo "Initial /etc/passwd line count: $(wc -l < /etc/passwd)"
echo "Initial /etc/group line count: $(wc -l < /etc/group)"

copy_entry() {
    local name="$1" src="$2" dst="$3" label="$4"
    if grep -q "^${name}:" "$dst" 2>/dev/null; then
        echo "  ${label}: ${name} already present in ${dst}"
        return 0
    fi
    local line
    line="$(grep "^${name}:" "$src" 2>/dev/null || true)"
    if [[ -z "$line" ]]; then
        echo "  ${label}: WARN ${name} not in ${src} -- skipping"
        return 0
    fi
    echo "  ${label}: adding ${name} to ${dst}: ${line}"
    echo "$line" >> "$dst"
}

for u in "${USERS_TO_COPY[@]}"; do
    copy_entry "$u" /usr/lib/passwd /etc/passwd "passwd"
done

for g in "${GROUPS_TO_COPY[@]}"; do
    copy_entry "$g" /usr/lib/group /etc/group "group"
done

# /etc/shadow and /etc/gshadow have no /usr/lib counterpart -- write directly.
# Format matches what fedora-kinoite-plasmalogin-workaround would have written.
if ! grep -q "^plasmalogin:" /etc/shadow 2>/dev/null; then
    echo "  shadow: adding plasmalogin to /etc/shadow"
    echo "plasmalogin:!*:::::::" >> /etc/shadow
else
    echo "  shadow: plasmalogin already in /etc/shadow"
fi
if ! grep -q "^plasmalogin:" /etc/gshadow 2>/dev/null; then
    echo "  gshadow: adding plasmalogin to /etc/gshadow"
    echo "plasmalogin:!*::" >> /etc/gshadow
else
    echo "  gshadow: plasmalogin already in /etc/gshadow"
fi

# Tell aurora's workaround service its job is done -- prevents it from running
# (and failing on read-only /etc) at every boot.
touch /etc/.fedora-kinoite-plasmalogin-workaround

echo "--- final state ---"
echo "/etc/passwd plasmalogin: $(grep '^plasmalogin:' /etc/passwd || echo MISSING)"
echo "/etc/group plasmalogin: $(grep '^plasmalogin:' /etc/group || echo MISSING)"
echo "/etc/group audio: $(grep '^audio:' /etc/group || echo MISSING)"
echo "/etc/group video: $(grep '^video:' /etc/group || echo MISSING)"
echo "=== fix-sysusers.sh: done ==="
