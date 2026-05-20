#!/usr/bin/env bash
# Build-time wrapper: run the same fix-up script that ships in the image, so
# fresh installs already have plasmalogin/plasma-setup in /etc/* without
# waiting for the runtime service.
set -euo pipefail

SCRIPT=/usr/libexec/kde-streamer-fix-sysusers
if [[ ! -x "$SCRIPT" ]]; then
    echo "ERROR: $SCRIPT not present in the build root -- did the 'files' module run first?" >&2
    exit 1
fi

echo "=== fix-sysusers.sh: invoking $SCRIPT at build time ==="
echo "Initial /etc/passwd line count: $(wc -l < /etc/passwd)"
echo "Initial /etc/group line count:  $(wc -l < /etc/group)"

"$SCRIPT"

echo "--- final state ---"
echo "/etc/passwd plasmalogin:   $(grep '^plasmalogin:'   /etc/passwd || echo MISSING)"
echo "/etc/passwd plasma-setup:  $(grep '^plasma-setup:'  /etc/passwd || echo MISSING)"
echo "/etc/group  plasmalogin:   $(grep '^plasmalogin:'   /etc/group  || echo MISSING)"
echo "/etc/group  audio:         $(grep '^audio:'         /etc/group  || echo MISSING)"
echo "/etc/group  video:         $(grep '^video:'         /etc/group  || echo MISSING)"
echo "=== fix-sysusers.sh: done ==="
